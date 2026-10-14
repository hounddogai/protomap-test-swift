import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_ReconcilePatientsRequest {
    static func forMedicalRecordWorkflowEndpointResumeMedicalRecordWorkflow0(
        _ input: Acme_Patients_V1_ResumeMedicalRecordWorkflowRequest
    ) -> Self {
        Acme_Patients_V1_ReconcilePatientsRequest.with {
            $0.context = input.context
            $0.patient = Acme_Patients_V1_Patient.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.etag = input.medicalRecord.audit.etag
                }
            }
        }
    }
}
