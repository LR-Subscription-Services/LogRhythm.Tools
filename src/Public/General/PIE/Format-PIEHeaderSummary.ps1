using namespace System.Collections.Generic
<#
    .SYNOPSIS
        Takes the output object generated by Invoke-PIE and produces summary suitable for LogRhythm Case.
    .OUTPUTS
        String containing header summary for the e-mail submitted and evaluated.
    .EXAMPLE
        Format-PIECaseSummary -ReportEvidence $ReportEvidence
        ---
        === E-mail Header Summary ===
        --- Submitted E-mail ---
        Reported On: 11/29/2020 3:02:06 PM
        Reported By: passmossis@outlook.com
        Subject: PhishAlert: Mimecast Test

        --- Evaluated E-mail ---
        Email Parsed Format: eml
        Sent On: 11/18/2020 16:15:23                Received On: 11/18/2020 16:17:10
        Sender: ThreatDNA@optiv.com                 Sender Display Name: ThreatDNA
        Subject: ThreatDNA ThreatBEAT Advisory: November 18, 2020 - CostaRicto Hacker-for-Hire Group

        --- PIE Metadata ---
        PIE Version: 3.7         LogRhythm Tools Version: 1.1.0
        Evaluation ID: 5e0d83c3-5402-4c73-a624-4c3b96e986fd
        Start: 2020-11-30T22485194Z    Stop: 2020-11-30T22495865Z     Duration: 00:01:06.7063393
    .NOTES
        PIE      
    .LINK
        https://github.com/LogRhythm-Tools/LogRhythm.Tools
#>
function Format-PIEHeaderSummary {
    [CmdLetBinding()]
    param( 
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [object] $ReportEvidence
    )

    Begin {
        $MsgHeaders = $ReportEvidence.EvaluationResults.Headers.Details
        if ($MsgHeaders.'authentication-results') {
            $AuthHeaders = $MsgHeaders.'authentication-results'
        }

        if ($MsgHeaders.'received-spf') {
            $ReceivedSpf = $MsgHeaders.'received-spf'
        }
        
        if ($MsgHeaders.'dkim-signature') {
            $DkimSignature = $MsgHeaders.'dkim-signature'
        }
    }

    Process {
        $CaseOutput = [list[String]]::new()

        $CaseOutput.Add("=== E-mail Header Summary ===")
        $CaseOutput.Add("--- General Header Information ---")
        $CaseOutput.Add("Message Id: $($MsgHeaders.'message-id')")
        $CaseOutput.Add("")
        $MsgTo = "To: $($MsgHeaders.to)"
        $MsgFrom = "From: $($MsgHeaders.from)"
        $CaseOutput.Add("$MsgTo $($MsgFrom.PadLeft(45-($MsgTo.length)+$($MsgFrom.length)))")
        $MimeVersion = "MIME Version: $($MsgHeaders.mimeversion)"
        $MsgSubject = "Subject: $($MsgHeaders.Subject)"
        $CaseOutput.Add("$MimeVersion $($MsgSubject.PadLeft(45-($MimeVersion.length)+$($MsgSubject.length)))")
        $CaseOutput.Add("")
        $MsgHeaders = $($ReportEvidence.EvaluationResults.Headers.Details)
        if ($MsgHeaders.received.count -ge 1) {
            $Received = $MsgHeaders.received | Sort-Object -Property step -Descending
            $CaseOutput.Add("--- Received ---")
            ForEach ($Step in $Received) {
                if ($Step.From) {
                    $FromName = "Sent From: $($Step.from.hostname)"
                    if ($Step.From.ipv4) {
                        $FromIP = "IPv4: $($Step.From.ipv4)"
                    } elseif ($Step.From.ipv6) {
                        $FromIP = "IPv6: $($Step.From.ipv6)"
                    }
                    $CaseOutput.Add("$FromName $($FromIP.PadLeft(45-($FromName.length)+$($FromIP.length)))")
                }
                
                if ($Step.By) {
                    $ByName = "Received By: $($Step.By.hostname)"
                    if ($Step.By.ipv4) {
                        $ByIP = "IPv4: $($Step.By.ipv4)"
                    } elseif ($Step.By.ipv6) {
                        $ByIP = "IPv6: $($Step.By.ipv6)"
                    }
                    $CaseOutput.Add("$ByName $($ByIp.PadLeft(45-($ByName.length)+$($ByIP.length)))")
                }
                
                $MXRole = "MX Role: $($Step.position)"
                $MXTimestamp = "Timestamp: $($Step.timestamp)"
                $CaseOutput.Add("$MXRole $($MXTimestamp.PadLeft(15-($MXRole.length)+$($MXTimestamp.length)))")
                $CaseOutput.Add("")
            }
        }
        
        if ($AuthHeaders) {
            $CaseOutput.Add("--- Authentication-Results ---")
            if ($AuthHeaders.spf.status) {
                $AH_SPFStatus = "Spf: $($AuthHeaders.spf.status)"
                $AH_SPFSummary = "Summary: $($AuthHeaders.spf.summary)"
                $CaseOutput.Add("$AH_SPFStatus $($AH_SPFSummary.PadLeft(15-($AH_SPFStatus.length)+$($AH_SPFSummary.length)))")
            }
            
            if ($AuthHeaders.dmarc.status) {
                $AH_DmarcStatus = "Dmarc: $($AuthHeaders.dmarc.status)"
                $AH_DmarcSummary = "Action: $($AuthHeaders.dmarc.action)"
                $CaseOutput.Add("$AH_DmarcStatus $($AH_DmarcSummary.PadLeft(15-($AH_DmarcStatus.length)+$($AH_DmarcSummary.length)))")
            }

            if ($AuthHeaders.dkim.status) {
                $AH_DKIMStatus = "Dkim: $($AuthHeaders.dkim.status)"
                $AH_DKIMSummary = "Summary: $($AuthHeaders.dkim.summary)"
                $CaseOutput.Add("$AH_DKIMStatus $($AH_DKIMSummary.PadLeft(15-($AH_DKIMStatus.length)+$($AH_DKIMSummary.length)))")
            }
            $CaseOutput.Add("")
        }
        if ($ReceivedSpf) {
            $CaseOutput.Add("--- Received-Spf ---")
            $SPF_Status = "Spf: $($ReceivedSpf.status)"
            $SPF_Summary = "Summary: $($ReceivedSpf.summary)"
            $CaseOutput.Add("$SPF_Status $($SPF_Summary.PadLeft(15-($SPF_Status.length)+$($SPF_Summary.length)))")
            $CaseOutput.Add("")
        }

        if ($DkimSignature) {
            $CaseOutput.Add("--- Dkim-Signature ---")
            $DKIM_Timestamp = "Timestamp: $($DKIMSignature.timestamp.modified)"
            $DKIM_Version = "Version: $($DkimSignature.version)"
            $CaseOutput.Add("$DKIM_Version $($DKIM_Timestamp.PadLeft(25-($DKIM_Version.length)+$($DKIM_Timestamp.length)))")
            $DKIM_QM = "Query Method: $($DkimSignature.query_method)"
            $DKIM_Alg = "Algorithm: $($DkimSignature.algorithm)"
            $CaseOutput.Add("$DKIM_QM $($DKIM_Alg.PadLeft(25-($DKIM_QM.length)+$($DKIM_Alg.length)))")
            $DKIM_Domain = "Domain: $($DKIMSignature.domain)"
            $DKIM_Selector = "Selector: $($DKIMSignature.selector)"
            $CaseOutput.Add("$DKIM_Domain $($DKIM_Selector.PadLeft(25-($DKIM_Domain.length)+$($DKIM_Selector.length)))")
            if ($DKIMSignature.dkim_dnsresolve.name) {
                $CaseOutput.Add("")
                $CaseOutput.Add("- Dkim-DNS-Resolve -")
                $CaseOutput.Add("DNS Name: $($DKIMSignature.dkim_dnsresolve.Name)")
                $CaseOutput.Add("TXT Record:")
                $CaseOutput.add("$($DKIMSignature.dkim_dnsresolve.Strings)")
            }
            $CaseOutput.Add("")
            $CaseOutput.Add("Header Fields: $($DKIMSignature.header_fields)")
            $CaseOutput.Add("Body Hash: $($DKIMSignature.body_hash)")
            $CaseOutput.Add("Signature: $($DKIMSignature.signature)")
            $CaseOutput.Add("")
        }

        return $CaseOutput | Out-String
    }
}
