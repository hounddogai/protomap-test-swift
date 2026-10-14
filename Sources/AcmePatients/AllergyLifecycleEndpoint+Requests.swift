import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Identity_V1_CreateUserRequest {
    static func forAllergyLifecycleEndpointTerminateAllergy1(
        _ input: Acme_Patients_V1_TerminateAllergyRequest,
        reply0: Acme_Patients_V1_ResolveMedicalRecordConflictResponse
    ) -> Self {
        Acme_Identity_V1_CreateUserRequest.with {
            $0.context = input.context
            $0.user = Acme_Identity_V1_User.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.email = reply0.medicalRecord.counterparty.email
                }
                $0.primaryAddress = Acme_Common_V1_PostalAddress.with {
                    $0.locality = reply0.medicalRecord.billingAddress.locality
                }
            }
        }
    }
}
