import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettlePerformersToken keeps of each BrowsePerformers response.
struct SettlePerformersTokenRecord {
    var nextPageToken: String
    var status: String
}

/// Where SettlePerformersToken hands each record.
protocol SettlePerformersTokenTarget {
    func apply(_ rec: SettlePerformersTokenRecord) async throws
}

/// Sends records to acme.appointments.v1.ProviderApprovalService.
struct SettlePerformersTokenProviderApproval: SettlePerformersTokenTarget {
    let client: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>

    func apply(_ rec: SettlePerformersTokenRecord) async throws {
        _ = try await client.recallProvider(.with {
            $0.details.approverEmail = rec.status
            $0.provider.providerID = rec.nextPageToken
        })
    }
}

/// Passes records to acme.patients.v1.PatientValidationService.
struct SettlePerformersTokenPatientValidation: SettlePerformersTokenTarget {
    let client: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>

    func apply(_ rec: SettlePerformersTokenRecord) async throws {
        _ = try await client.previewPatient(.with {
            $0.patient.patientID = rec.nextPageToken
        })
    }
}

/// Sends records to acme.telehealth.v1.TriageLifecycleService.
struct SettlePerformersTokenTriageLifecycle: SettlePerformersTokenTarget {
    let client: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>

    func apply(_ rec: SettlePerformersTokenRecord) async throws {
        let request = Acme_Telehealth_V1_ScheduleTriageExpiryRequest.with {
            $0.triageID = rec.nextPageToken
            $0.triage.triageID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scheduleTriageExpiry(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct SettlePerformersTokenLogOnly: SettlePerformersTokenTarget {
    let logger = Logger(label: "acme.settle-performers-token")

    func apply(_ rec: SettlePerformersTokenRecord) async throws {
        logger.info("No sink for record", metadata: ["nextPageToken": .string(rec.nextPageToken)])
    }
}

/// Reads acme.performers.v1.PerformerQueryService/BrowsePerformers and hands what it keeps to the sink of its kind.
enum SettlePerformersToken {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Performers_V1_PerformerQueryService.Client(wrapping: mesh)
        let found = try await upstream.browsePerformers(.with { $0.orderBy = "nightly-settle-performers-token" })
        let record = SettlePerformersTokenRecord(
            nextPageToken: found.pageInfo.nextPageToken,
            status: found.result.status
        )
        try await deliver("patient-validation", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: SettlePerformersTokenRecord, _ mesh: MeshClient) async throws {
        var sink: any SettlePerformersTokenTarget = SettlePerformersTokenLogOnly()
        switch kind {
        case "provider-approval":
            sink = SettlePerformersTokenProviderApproval(client: Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh))
        case "patient-validation":
            sink = SettlePerformersTokenPatientValidation(client: Acme_Patients_V1_PatientValidationService.Client(wrapping: mesh))
        case "triage-lifecycle":
            sink = SettlePerformersTokenTriageLifecycle(client: Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
