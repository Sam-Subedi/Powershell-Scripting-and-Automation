$MailParams = @{
    To          = "admin@abc.local"
    From        = "abc.local"
    Subject     = "Daily AD Health Report - $Forest"
    Body        = "Please find the attached Active Directory Health Report for $Forest."
    Attachments = $ReportPath
    SmtpServer  = "smtp.@abc.local"
}
Send-MailMessage @MailParams
