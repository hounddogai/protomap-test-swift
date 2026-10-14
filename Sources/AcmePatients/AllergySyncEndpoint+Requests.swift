import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_ScorePatientRequest {
    static func forAllergySyncEndpointPushAllergy0(
        _ input: Acme_Patients_V1_PushAllergyRequest
    ) -> Self {
        Acme_Patients_V1_ScorePatientRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.patientID = input.allergy.subject.patientID
            }
        }
    }
}
