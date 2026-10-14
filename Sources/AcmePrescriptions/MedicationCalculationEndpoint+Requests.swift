import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Search_V1_UpdateSearchIndexRequest {
    static func forMedicationCalculationEndpointCalculateMedication3(
        _ input: Acme_Prescriptions_V1_CalculateMedicationRequest,
        reply0: Acme_Boxoffice_V1_UpdateBoxOfficeSaleResponse,
        reply2: Acme_Prescriptions_V1_CalculatePrescriptionResponse
    ) -> Self {
        Acme_Search_V1_UpdateSearchIndexRequest.with {
            $0.context = input.context
            $0.searchIndex = Acme_Search_V1_SearchIndex.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.boxOfficeSale.audit.createdBy
                }
                $0.components = [
                    "primary": Acme_Search_V1_SearchIndexComponent.with {
                        $0.quantity = input.medication.components["primary", default: .init()].quantity
                    }
                ]
                $0.owner = Acme_Identity_V1_UserRef.with {
                    $0.displayName = reply2.prescription.counterparty.displayName
                }
            }
        }
    }
}
