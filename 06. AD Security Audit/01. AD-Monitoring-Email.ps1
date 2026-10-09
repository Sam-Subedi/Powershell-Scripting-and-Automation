$MailParams = @{
    To          = "admin@labshandson.in"
    From        = "AD-Monitor@@labshandson.in"
    Subject     = "Daily AD Health Report - $Forest"
    Body        = "Please find the attached Active Directory Health Report for $Forest."
    Attachments = $ReportPath
    SmtpServer  = "smtp.@labshandson.in"
}
Send-MailMessage @MailParams