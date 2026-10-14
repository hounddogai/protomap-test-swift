import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Ledger_V1_SearchLedgerAccountsRequest {
    static func forRefillWorkflowEndpointSignalRefillWorkflow1(
        _ input: Acme_Prescriptions_V1_SignalRefillWorkflowRequest
    ) -> Self {
        Acme_Ledger_V1_SearchLedgerAccountsRequest.with {
            $0.context = input.context
            $0.filter = Acme_Ledger_V1_SearchLedgerAccountsRequest.Filter.with {
                $0.createdAfter = input.refill.audit.createdAt
            }
        }
    }
}
