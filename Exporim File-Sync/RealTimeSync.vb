'This file is part of Exporim File-Sync.
'
'Exporim File-Sync is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
'Exporim File-Sync is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
'You should have received a copy of the GNU General Public License along with Exporim File-Sync.  If not, see <http://www.gnu.org/licenses/>.

Option Strict On

' Watches each profile's source folder (when it has "Real-time sync" enabled) and triggers a
' quiet sync a short quiet period after the last detected change, instead of waiting for the
' next scheduled run. Only the source side is watched: for a one-way mirror (the common case)
' the sync engine only ever writes to the destination, so this can't feed back into itself; for
' a two-way profile, changes made only on the destination side still need a scheduled/manual run.
Friend Module RealTimeSync
    Private Const DebounceMilliseconds As Integer = 3000

    Private ReadOnly Watchers As New Dictionary(Of String, IO.FileSystemWatcher)
    Private ReadOnly DebounceTimers As New Dictionary(Of String, Timer)
    Private ReadOnly SyncsInProgress As New HashSet(Of String)
    Private ReadOnly PendingRetrigger As New HashSet(Of String)

    ''' <summary>Reconciles the watcher set with the current profile list and their "Real-time sync" setting. Safe to call repeatedly (eg. every time profiles are reloaded).</summary>
    Friend Sub RefreshWatchers()
        For Each Name As String In New List(Of String)(Watchers.Keys)
            If Not Profiles.ContainsKey(Name) OrElse Not Profiles(Name).GetSetting(Of Boolean)(ProfileSetting.RealTimeSync, False) Then StopWatching(Name)
        Next

        For Each Entry As KeyValuePair(Of String, ProfileHandler) In Profiles
            If Entry.Value.GetSetting(Of Boolean)(ProfileSetting.RealTimeSync, False) AndAlso Not Watchers.ContainsKey(Entry.Key) Then StartWatching(Entry.Key, Entry.Value)
        Next
    End Sub

    Friend Sub StopAll()
        For Each Name As String In New List(Of String)(Watchers.Keys)
            StopWatching(Name)
        Next
    End Sub

    Private Sub StartWatching(ByVal ProfileName As String, ByVal Handler As ProfileHandler)
        Dim SourcePath As String = ProfileHandler.TranslatePath(Handler.GetSetting(Of String)(ProfileSetting.Source, ""))
        If SourcePath = "" OrElse Not IO.Directory.Exists(SourcePath) Then Exit Sub

        Try
            Dim Watcher As New IO.FileSystemWatcher(SourcePath) With {
                .IncludeSubdirectories = True,
                .NotifyFilter = IO.NotifyFilters.FileName Or IO.NotifyFilters.DirectoryName Or IO.NotifyFilters.LastWrite Or IO.NotifyFilters.Size
            }
            AddHandler Watcher.Changed, AddressOf OnFileSystemEvent
            AddHandler Watcher.Created, AddressOf OnFileSystemEvent
            AddHandler Watcher.Deleted, AddressOf OnFileSystemEvent
            AddHandler Watcher.Renamed, AddressOf OnFileSystemEvent
            AddHandler Watcher.Error, AddressOf OnWatcherError
            Watcher.EnableRaisingEvents = True

            Watchers.Add(ProfileName, Watcher)
            ConfigHandler.LogAppEvent(String.Format("Real-time sync: watching ""{0}"" for profile ""{1}"".", SourcePath, ProfileName))
        Catch Ex As Exception
            ConfigHandler.LogAppEvent(String.Format("Real-time sync: could not watch ""{0}"" for profile ""{1}"": {2}", SourcePath, ProfileName, Ex.Message))
        End Try
    End Sub

    Private Sub StopWatching(ByVal ProfileName As String)
        If Watchers.ContainsKey(ProfileName) Then
            Watchers(ProfileName).EnableRaisingEvents = False
            Watchers(ProfileName).Dispose()
            Watchers.Remove(ProfileName)
        End If

        If DebounceTimers.ContainsKey(ProfileName) Then
            DebounceTimers(ProfileName).Stop()
            DebounceTimers(ProfileName).Dispose()
            DebounceTimers.Remove(ProfileName)
        End If

        PendingRetrigger.Remove(ProfileName)
    End Sub

    Private Function FindProfileName(ByVal Watcher As IO.FileSystemWatcher) As String
        For Each Entry As KeyValuePair(Of String, IO.FileSystemWatcher) In Watchers
            If Entry.Value Is Watcher Then Return Entry.Key
        Next
        Return Nothing
    End Function

    ' Runs on a ThreadPool thread (FileSystemWatcher's own callback thread), not the UI thread.
    Private Sub OnFileSystemEvent(ByVal sender As Object, ByVal e As IO.FileSystemEventArgs)
        HopToUiThreadAndSchedule(CType(sender, IO.FileSystemWatcher))
    End Sub

    Private Sub OnWatcherError(ByVal sender As Object, ByVal e As IO.ErrorEventArgs)
        ' Typically an internal buffer overflow under very heavy/rapid changes: we can't know
        ' exactly what was missed, so the safe recovery is simply to resync now.
        HopToUiThreadAndSchedule(CType(sender, IO.FileSystemWatcher))
    End Sub

    Private Sub HopToUiThreadAndSchedule(ByVal Watcher As IO.FileSystemWatcher)
        Dim ProfileName As String = FindProfileName(Watcher)
        If ProfileName Is Nothing Then Exit Sub

        Try
            MainFormInstance.BeginInvoke(New Action(Sub() ScheduleSync(ProfileName)))
        Catch
            'MainForm may be mid-recreation, or the app mid-shutdown; the next change (or the
            'profile's own schedule/manual run) will pick this up.
        End Try
    End Sub

    ' Everything below only ever runs on the UI thread (called via BeginInvoke above, or from
    ' Timer.Tick / the SyncFinished event, both already UI-thread-affine).
    Private Sub ScheduleSync(ByVal ProfileName As String)
        If SyncsInProgress.Contains(ProfileName) Then
            PendingRetrigger.Add(ProfileName) 'Catch up once the running sync finishes.
            Exit Sub
        End If

        If Not DebounceTimers.ContainsKey(ProfileName) Then
            Dim NewTimer As New Timer With {.Interval = DebounceMilliseconds}
            AddHandler NewTimer.Tick, Sub(sender As Object, e As EventArgs) OnDebounceElapsed(ProfileName)
            DebounceTimers.Add(ProfileName, NewTimer)
        End If

        Dim DebounceTimer As Timer = DebounceTimers(ProfileName)
        DebounceTimer.Stop()
        DebounceTimer.Start()
    End Sub

    Private Sub OnDebounceElapsed(ByVal ProfileName As String)
        If DebounceTimers.ContainsKey(ProfileName) Then DebounceTimers(ProfileName).Stop()
        If Not Watchers.ContainsKey(ProfileName) Then Exit Sub 'Watching was turned off while we were waiting.
        If Not Profiles.ContainsKey(ProfileName) Then Exit Sub 'Profile was deleted while we were waiting.
        If SyncsInProgress.Contains(ProfileName) Then PendingRetrigger.Add(ProfileName) : Exit Sub

        SyncsInProgress.Add(ProfileName)
        ConfigHandler.LogAppEvent(String.Format("Real-time sync: change detected, syncing ""{0}"".", ProfileName))

        Dim SyncForm As New SynchronizeForm(ProfileName, False, True, False)
        AddHandler SyncForm.SyncFinished, AddressOf OnTriggeredSyncFinished
        SyncForm.StartSynchronization(False)
    End Sub

    Private Sub OnTriggeredSyncFinished(ByVal Name As String, ByVal Completed As Boolean)
        SyncsInProgress.Remove(Name)
        If PendingRetrigger.Remove(Name) Then ScheduleSync(Name)
    End Sub
End Module
