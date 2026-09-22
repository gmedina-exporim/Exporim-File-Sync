'This file is part of Exporim File-Sync.
'
'Exporim File-Sync is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
'Exporim File-Sync is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
'You should have received a copy of the GNU General Public License along with Exporim File-Sync.  If not, see <http://www.gnu.org/licenses/>.
'Created by:	Clément Pit--Claudel.
'Web site:		https://github.com/gmedina-exporim/Exporim-File-Sync.

Friend Module Updates
    Private Const GitHubRepo As String = "gmedina-exporim/Exporim-File-Sync"

    Private ReadOnly HttpClient As New Net.Http.HttpClient()

    Public Sub CheckForUpdates(Optional ByVal RoutineCheck As Boolean = True)
        Try
            Dim LatestVersionTag As String = GetLatestReleaseTag()
            Dim LatestVersion As String = If(LatestVersionTag.StartsWith("v"), LatestVersionTag.Substring(1), LatestVersionTag)

            If ((New Version(LatestVersion)) > (New Version(Application.ProductVersion))) Then
                If Interaction.ShowMsg(String.Format(Translation.Translate("\UPDATE_MSG"), Application.ProductVersion, LatestVersion), Translation.Translate("\UPDATE_TITLE"), MessageBoxButtons.YesNo, MessageBoxIcon.Question) = DialogResult.Yes Then
                    Interaction.StartProcess(String.Format("https://github.com/{0}/releases/latest", GitHubRepo))
                    If ProgramConfig.CanGoOn Then MainFormInstance.Invoke(New Action(AddressOf Application.Exit))
                End If
            Else
                If Not RoutineCheck Then Interaction.ShowMsg(Translation.Translate("\NO_UPDATES"), , , MessageBoxIcon.Information)
            End If
        Catch Ex As InvalidOperationException
            'Some form couldn't close properly because of thread accesses
            Interaction.ShowDebug(Ex.ToString)
        Catch Ex As Exception
            If Not RoutineCheck Then Interaction.ShowMsg(Translation.Translate("\UPDATE_ERROR") & Environment.NewLine & Ex.Message, Translation.Translate("\UPDATE_ERROR_TITLE"), , MessageBoxIcon.Error)
            Interaction.ShowDebug(Ex.Message & Environment.NewLine & Ex.StackTrace)
        End Try
    End Sub

    Private Function GetLatestReleaseTag() As String
        Dim Request As New Net.Http.HttpRequestMessage(Net.Http.HttpMethod.Get, String.Format("https://api.github.com/repos/{0}/releases/latest", GitHubRepo))
        Request.Headers.Add("User-Agent", "Exporim-File-Sync-Updater")
        Request.Headers.Add("Accept", "application/vnd.github+json")

        Dim Response As Net.Http.HttpResponseMessage = HttpClient.Send(Request)
        Response.EnsureSuccessStatusCode()

        Using ResponseStream As IO.Stream = Response.Content.ReadAsStream()
            Using JsonDoc As Text.Json.JsonDocument = Text.Json.JsonDocument.Parse(ResponseStream)
                Return JsonDoc.RootElement.GetProperty("tag_name").GetString()
            End Using
        End Using
    End Function
End Module
