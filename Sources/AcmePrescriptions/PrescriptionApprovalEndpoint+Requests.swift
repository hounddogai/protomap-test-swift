import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_CheckPatientEligibilityRequest {
    static func forPrescriptionApprovalEndpointDelegatePrescriptionApproval1(
        _ input: Acme_Prescriptions_V1_DelegatePrescriptionApprovalRequest,
        reply0: Acme_Careplans_V1_RecalculateCareGoalsResponse
    ) -> Self {
        Acme_Patients_V1_CheckPatientEligibilityRequest.with {
            $0.context = input.context
            $0.details = Acme_Patients_V1_CheckPatientEligibilityRequest.Details.with {
                $0.contact = Acme_Common_V1_ContactInfo.with {
                    $0.preferredChannel = reply0.careGoal.requester.preferredChannel
                }
            }
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.relationshipManager = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.details.approver.displayName
                    $0.email = reply0.careGoal.requester.email
                }
            }
        }
    }
}
