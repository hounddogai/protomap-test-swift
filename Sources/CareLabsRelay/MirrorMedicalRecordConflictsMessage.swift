import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorMedicalRecordConflictsMessage keeps of each ListMedicalRecordConflicts response.
struct MirrorMedicalRecordConflictsMessageRecord {
    var message: String
    var nextPageToken: String
    var correlationID: String
    var status: String
}

/// Where MirrorMedicalRecordConflictsMessage hands each record.
protocol MirrorMedicalRecordConflictsMessageDestination {
    func forward(_ rec: MirrorMedicalRecordConflictsMessageRecord) async throws
}

/// Hands records to acme.appointments.v1.ProviderApprovalService.
struct MirrorMedicalRecordConflictsMessageProviderApproval: MirrorMedicalRecordConflictsMessageDestination {
    let client: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>

    func forward(_ rec: MirrorMedicalRecordConflictsMessageRecord) async throws {
        _ = try await client.getProviderApprovalStatus(.with {
            $0.providerID = rec.message
        })
    }
}

/// Passes records to acme.shows.v1.ShowCalculationService.
struct MirrorMedicalRecordConflictsMessageShowCalculation: MirrorMedicalRecordConflictsMessageDestination {
    let client: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>

    func forward(_ rec: MirrorMedicalRecordConflictsMessageRecord) async throws {
        _ = try await client.quoteShow(.with {
            $0.reason = rec.message
            $0.show.showID = rec.correlationID
            $0.showID = rec.nextPageToken
        })
    }
}

/// Reads acme.patients.v1.MedicalRecordSyncService/ListMedicalRecordConflicts and hands what it keeps to the sink of its kind.
enum MirrorMedicalRecordConflictsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: mesh)
        let response = try await reader.listMedicalRecordConflicts(.with { $0.orderBy = "nightly-mirror-medical-record-conflicts-message" })
        let row = MirrorMedicalRecordConflictsMessageRecord(
            message: Kit.Text.normalize(response.result.message),
            nextPageToken: Kit.Text.normalize(response.pageInfo.nextPageToken),
            correlationID: Kit.Text.normalize(response.result.correlationID),
            status: response.result.status
        )
        let sinks: [String: any MirrorMedicalRecordConflictsMessageDestination] = [
            "provider-approval": MirrorMedicalRecordConflictsMessageProviderApproval(client: Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh)),
            "show-calculation": MirrorMedicalRecordConflictsMessageShowCalculation(client: Acme_Shows_V1_ShowCalculationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "provider-approval" {
                continue
            }
            try await sink.forward(row)
        }
    }
}
