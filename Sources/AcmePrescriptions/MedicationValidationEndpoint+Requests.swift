import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Careplans_V1_NormalizeVitalRequest {
    static func forMedicationValidationEndpointLintMedications3(
        _ input: Acme_Prescriptions_V1_LintMedicationsRequest
    ) -> Self {
        Acme_Careplans_V1_NormalizeVitalRequest.with {
            $0.context = input.context
            $0.details = Acme_Careplans_V1_NormalizeVitalRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = input.details.contact.email
                    $0.name = input.details.contact.name
                    $0.preferredChannel = input.details.contact.preferredChannel
                }
            }
        }
    }
}
