import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyCollectionCaseStatus keeps of each UpdateCollectionCase response.
struct CopyCollectionCaseStatusRecord {
    var status: String
    var collectionCaseID: String
    var message: String
    var correlationID: String
}

/// Where CopyCollectionCaseStatus hands each record.
protocol CopyCollectionCaseStatusSink {
    func write(_ rec: CopyCollectionCaseStatusRecord) async throws
}

/// Sends records to acme.patients.v1.MedicalRecordReportingService.
struct CopyCollectionCaseStatusMedicalRecordReporting: CopyCollectionCaseStatusSink {
    let client: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>

    func write(_ rec: CopyCollectionCaseStatusRecord) async throws {
        _ = try await client.shareMedicalRecordReport(.with {
            $0.details.channel = rec.collectionCaseID
            $0.details.templateID = rec.correlationID
            $0.medicalRecordID = rec.message
        })
    }
}

/// Passes records to acme.itsm.v1.IncidentService.
struct CopyCollectionCaseStatusIncident: CopyCollectionCaseStatusSink {
    let client: Acme_Itsm_V1_IncidentService.Client<MeshTransport>

    func write(_ rec: CopyCollectionCaseStatusRecord) async throws {
        _ = try await client.listIncidents(.with {
            $0.filter.ownerID = rec.message
        })
    }
}

/// Reads acme.collections.v1.CollectionCaseService/UpdateCollectionCase and hands what it keeps to the sink of its kind.
enum CopyCollectionCaseStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Collections_V1_CollectionCaseService.Client(wrapping: mesh)
        let got = try await source.updateCollectionCase(.init())
        let rec = CopyCollectionCaseStatusRecord(
            status: Kit.Text.normalize(got.result.status),
            collectionCaseID: got.collectionCase.collectionCaseID,
            message: got.result.message,
            correlationID: Kit.Text.normalize(got.result.correlationID)
        )
        let sinks: [String: any CopyCollectionCaseStatusSink] = [
            "medical-record-reporting": CopyCollectionCaseStatusMedicalRecordReporting(client: Acme_Patients_V1_MedicalRecordReportingService.Client(wrapping: mesh)),
            "incident": CopyCollectionCaseStatusIncident(client: Acme_Itsm_V1_IncidentService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "incident" {
                continue
            }
            try await sink.write(rec)
        }
    }
}
