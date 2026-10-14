import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Ledger_V1_PreviewLedgerAccountRequest {
    static func forVideoVisitCalculationEndpointGetVideoVisitRates0(
        _ input: Acme_Telehealth_V1_GetVideoVisitRatesRequest
    ) -> Self {
        Acme_Ledger_V1_PreviewLedgerAccountRequest.with {
            $0.context = input.context
            $0.details = Acme_Ledger_V1_PreviewLedgerAccountRequest.Details.with {
                $0.locale = input.context.locale
            }
            $0.ledgerAccount = Acme_Ledger_V1_LedgerAccount.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.context.actor.email
                }
            }
        }
    }
}
