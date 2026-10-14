import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Identity_V1_CreateUserRequest {
    static func forPatientCalculationEndpointRecalculatePatients1(
        _ input: Acme_Patients_V1_RecalculatePatientsRequest
    ) -> Self {
        Acme_Identity_V1_CreateUserRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.updatedAt = input.patient.audit.updatedAt
                }
                $0.preferences = Acme_Identity_V1_UserPreferences.with {
                    $0.marketingOptIn = input.patient.preferences.marketingOptIn
                }
            }
        }
    }
}
