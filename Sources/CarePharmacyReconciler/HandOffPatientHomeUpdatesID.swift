import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffPatientHomeUpdatesID keeps of each UnsubscribePatientHomeUpdates response.
struct HandOffPatientHomeUpdatesIDRecord {
    var patientHomeID: String
    var correlationID: String
}

/// Where HandOffPatientHomeUpdatesID hands each record.
protocol HandOffPatientHomeUpdatesIDSink {
    func push(_ rec: HandOffPatientHomeUpdatesIDRecord) async throws
}

/// Passes records to acme.patients.v1.MedicalRecordLifecycleService.
struct HandOffPatientHomeUpdatesIDMedicalRecordLifecycle: HandOffPatientHomeUpdatesIDSink {
    let client: Acme_Patients_V1_MedicalRecordLifecycleService.Client<MeshTransport>

    func push(_ rec: HandOffPatientHomeUpdatesIDRecord) async throws {
        _ = try await client.getMedicalRecordLifecycle(.with {
            $0.medicalRecordID = rec.patientHomeID
        })
    }
}

/// Sends records to acme.shows.v1.ShowService.
struct HandOffPatientHomeUpdatesIDShow: HandOffPatientHomeUpdatesIDSink {
    let client: Acme_Shows_V1_ShowService.Client<MeshTransport>

    func push(_ rec: HandOffPatientHomeUpdatesIDRecord) async throws {
        _ = try await client.cloneShow(.with {
            $0.show.title = rec.patientHomeID
            $0.requestID = rec.correlationID
        })
    }
}

/// Sends records to acme.configuration.v1.ConfigSetService.
struct HandOffPatientHomeUpdatesIDConfigSet: HandOffPatientHomeUpdatesIDSink {
    let client: Acme_Configuration_V1_ConfigSetService.Client<MeshTransport>

    func push(_ rec: HandOffPatientHomeUpdatesIDRecord) async throws {
        let request = Acme_Configuration_V1_DeleteConfigSetRequest.with {
            $0.configSetID = rec.correlationID
            $0.reason = rec.patientHomeID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.deleteConfigSet(request)
        }
    }
}

/// Reads acme.patientapp.v1.PatientHomeNotificationService/UnsubscribePatientHomeUpdates and hands what it keeps to the sink of its kind.
enum HandOffPatientHomeUpdatesID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patientapp_V1_PatientHomeNotificationService.Client(wrapping: mesh)
        let response = try await reader.unsubscribePatientHomeUpdates(.with { $0.reason = "main-hand-off-patient-home-updates-id" })
        let rec = HandOffPatientHomeUpdatesIDRecord(
            patientHomeID: response.patientHome.patientHomeID,
            correlationID: Kit.Text.normalize(response.result.correlationID)
        )
        let sinks: [String: any HandOffPatientHomeUpdatesIDSink] = [
            "medical-record-lifecycle": HandOffPatientHomeUpdatesIDMedicalRecordLifecycle(client: Acme_Patients_V1_MedicalRecordLifecycleService.Client(wrapping: mesh)),
            "show": HandOffPatientHomeUpdatesIDShow(client: Acme_Shows_V1_ShowService.Client(wrapping: mesh)),
            "config-set": HandOffPatientHomeUpdatesIDConfigSet(client: Acme_Configuration_V1_ConfigSetService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "config-set" {
                continue
            }
            try await sink.push(rec)
        }
    }
}
