'This file is part of Exporim File-Sync.
'
'Exporim File-Sync is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
'Exporim File-Sync is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
'You should have received a copy of the GNU General Public License along with Exporim File-Sync.  If not, see <http://www.gnu.org/licenses/>.
'Created by:	Clément Pit--Claudel.
'Web site:		https://github.com/gmedina-exporim/Exporim-File-Sync.

Public Class AboutForm
    Private Shared Sub SetLinkArea(ByVal Link As LinkLabel)
        If Link.Text.IndexOf("\"c) = -1 Or Link.Text.IndexOf("/"c) = -1 Then Exit Sub

        Dim Area As New LinkArea
        Area.Start = Link.Text.IndexOf("\"c)
        Link.Text = Link.Text.Remove(Area.Start, 1)
        Area.Length = Link.Text.IndexOf("/"c) - Area.Start
        Link.Text = Link.Text.Remove(Area.Start + Area.Length, 1)
        Link.LinkArea = Area
    End Sub

    Private Sub About_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Translation.TranslateControl(Me)
        Interaction.ThemeLinkLabels(Me)
        VersionInfo.Text = VersionInfo.Text.Replace("%version%", String.Format("{0} (r{1})", Application.ProductVersion.TrimEnd(".0".ToCharArray), Revision.Build))

        SetLinkArea(BugReport)
        SetLinkArea(ContactLink)
        SetLinkArea(LinkToLicense)
        SetLinkArea(LinkToProductPage)
        SetLinkArea(LinkToWebsite)
        SetLinkArea(VersionInfo)

        ProgramConfig.LoadProgramSettings()
        LanguageHandler.FillLanguageListBox(LanguagesList)
        UpdatesOption.Checked = ProgramConfig.GetProgramSetting(Of Boolean)(ProgramSetting.AutoUpdates, False)

        ThemeList.Items.Clear()
        ThemeList.Items.AddRange({Translation.Translate("\THEME_SYSTEM"), Translation.Translate("\THEME_LIGHT"), Translation.Translate("\THEME_DARK")})
        ThemeList.SelectedIndex = Array.IndexOf({"System", "Light", "Dark"}, ProgramConfig.GetProgramSetting(Of String)(ProgramSetting.ColorMode, ProgramSetting.DefaultColorMode))
        If ThemeList.SelectedIndex = -1 Then ThemeList.SelectedIndex = 0
    End Sub

    Private Sub LinkToProductPage_LinkClicked(ByVal sender As System.Object, ByVal e As System.Windows.Forms.LinkLabelLinkClickedEventArgs) Handles LinkToProductPage.LinkClicked
        Interaction.StartProcess(ProgramSetting.Website)
    End Sub

    Private Sub LinkToWebsite_LinkClicked(ByVal sender As System.Object, ByVal e As System.Windows.Forms.LinkLabelLinkClickedEventArgs) Handles LinkToWebsite.LinkClicked
        Interaction.StartProcess(ProgramSetting.UserWeb)
    End Sub

    Private Sub VersionInfo_LinkClicked(ByVal sender As System.Object, ByVal e As System.Windows.Forms.LinkLabelLinkClickedEventArgs) Handles VersionInfo.LinkClicked
        Updates.CheckForUpdates(False)
    End Sub

    Private Sub ContactLink_LinkClicked(ByVal sender As System.Object, ByVal e As System.Windows.Forms.LinkLabelLinkClickedEventArgs) Handles ContactLink.LinkClicked
        Interaction.StartProcess("https://github.com/gmedina-exporim/Exporim-File-Sync/issues")
    End Sub

    Private Sub LinkToLicense_LinkClicked(ByVal sender As System.Object, ByVal e As System.Windows.Forms.LinkLabelLinkClickedEventArgs) Handles LinkToLicense.LinkClicked
        Interaction.StartProcess("http://www.gnu.org/licenses/gpl.html")
    End Sub

    Private Sub BugReport_LinkClicked(ByVal sender As System.Object, ByVal e As System.Windows.Forms.LinkLabelLinkClickedEventArgs) Handles BugReport.LinkClicked
        Interaction.StartProcess("https://github.com/gmedina-exporim/Exporim-File-Sync/issues")
    End Sub

    Private Sub AboutForm_FormClosed(ByVal sender As System.Object, ByVal e As System.Windows.Forms.FormClosedEventArgs) Handles MyBase.FormClosed
        If LanguagesList.SelectedIndex <> -1 Then
            Dim SelectedLanguage As String = LanguagesList.SelectedItem.ToString.Split("-"c)(0).Trim
            Dim LanguageChanged As Boolean = ProgramConfig.GetProgramSetting(Of String)(ProgramSetting.Language, ProgramSetting.DefaultLanguage) <> SelectedLanguage

            ProgramConfig.SetProgramSetting(Of String)(ProgramSetting.Language, SelectedLanguage)

            If LanguageChanged Then
                ReloadNeeded = True
                Translation = LanguageHandler.GetSingleton(True)
            End If
        End If

        ProgramConfig.SetProgramSetting(Of Boolean)(ProgramSetting.AutoUpdates, UpdatesOption.Checked)

        If ThemeList.SelectedIndex <> -1 Then
            Dim SelectedColorMode As String = {"System", "Light", "Dark"}(ThemeList.SelectedIndex)
            Dim ColorModeChanged As Boolean = ProgramConfig.GetProgramSetting(Of String)(ProgramSetting.ColorMode, ProgramSetting.DefaultColorMode) <> SelectedColorMode
            ProgramConfig.SetProgramSetting(Of String)(ProgramSetting.ColorMode, SelectedColorMode)
            If ColorModeChanged Then Interaction.ShowMsg(Translation.Translate("\THEME_RESTART_NOTICE"), , , MessageBoxIcon.Information)
        End If

        ProgramConfig.SaveProgramSettings()
    End Sub
End Class
