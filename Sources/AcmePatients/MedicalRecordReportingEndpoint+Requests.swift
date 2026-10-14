import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Patients_V1_ReconcileMedicalRecordsRequest {
    static func forMedicalRecordReportingEndpointShareMedicalRecordReport2(
        _ input: Acme_Patients_V1_ShareMedicalRecordReportRequest,
        reply0: Acme_Telehealth_V1_ScheduleVisitNoteExpiryResponse
    ) -> Self {
        Acme_Patients_V1_ReconcileMedicalRecordsRequest.with {
            $0.context = input.context
            $0.medicalRecord = Acme_Patients_V1_MedicalRecord.with {
                $0.billingAddress = Acme_Common_V1_PostalAddress.with {
                    $0.region = reply0.visitNote.billingAddress.region
                }
            }
        }
    }
}
