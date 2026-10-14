import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Accounting_V1_CreateChartOfAccountsRequest {
    static func forPatientReportingEndpointSchedulePatientReport0(
        _ input: Acme_Patients_V1_SchedulePatientReportRequest
    ) -> Self {
        Acme_Accounting_V1_CreateChartOfAccountsRequest.with {
            $0.chartOfAccounts = Acme_Accounting_V1_ChartOfAccounts.with {
                $0.children = [
                    Acme_Accounting_V1_ChartOfAccounts.with {
                        $0.manager = Acme_Identity_V1_UserRef.with {
                            $0.email = input.context.actor.email
                        }
                    }
                ]
            }
            $0.context = input.context
        }
    }
}
