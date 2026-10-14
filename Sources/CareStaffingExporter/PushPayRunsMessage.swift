import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushPayRunsMessage keeps of each SummarizePayRuns response.
struct PushPayRunsMessageRecord {
    var message: String
    var correlationID: String
    var status: String
    var timezone: String
}

/// Where PushPayRunsMessage hands each record.
protocol PushPayRunsMessageTarget {
    func apply(_ rec: PushPayRunsMessageRecord) async throws
}

/// Writes records to acme.patients.v1.PatientQueryService.
struct PushPayRunsMessagePatientQuery: PushPayRunsMessageTarget {
    let client: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>

    func apply(_ rec: PushPayRunsMessageRecord) async throws {
        _ = try await client.summarizePatients(.with {
            $0.details.format = rec.timezone
            $0.details.cron = rec.status
            $0.patientID = rec.correlationID
        })
    }
}

/// Passes records to acme.authorization.v1.AccessPolicyQueryService.
struct PushPayRunsMessageAccessPolicyQuery: PushPayRunsMessageTarget {
    let client: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>

    func apply(_ rec: PushPayRunsMessageRecord) async throws {
        _ = try await client.peekAccessPolicy(.with {
            $0.accessPolicyID = rec.correlationID
        })
    }
}

/// Sends records to acme.appointments.v1.ClinicSlotApprovalService.
struct PushPayRunsMessageClinicSlotApproval: PushPayRunsMessageTarget {
    let client: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>

    func apply(_ rec: PushPayRunsMessageRecord) async throws {
        _ = try await client.approveClinicSlot(.with {
            $0.clinicSlot.clinicSlotID = rec.timezone
            $0.clinicSlotID = rec.correlationID
        })
    }
}

/// Hands records to acme.dispatch.v1.DispatchOrderQueryService.
struct PushPayRunsMessageDispatchOrderQuery: PushPayRunsMessageTarget {
    let client: Acme_Dispatch_V1_DispatchOrderQueryService.Client<MeshTransport>

    func apply(_ rec: PushPayRunsMessageRecord) async throws {
        _ = try await client.browseDispatchOrders(.with {
            $0.page.pageToken = rec.timezone
            $0.filter.query = rec.correlationID
            $0.orderBy = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct PushPayRunsMessageLogOnly: PushPayRunsMessageTarget {
    let logger = Logger(label: "acme.push-pay-runs-message")

    func apply(_ rec: PushPayRunsMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.payroll.v1.PayRunQueryService/SummarizePayRuns and hands what it keeps to the sink of its kind.
enum PushPayRunsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Payroll_V1_PayRunQueryService.Client(wrapping: mesh)
        let reply = try await upstream.summarizePayRuns(.with { $0.payRunID = "default-push-pay-runs-message" })
        let rec = PushPayRunsMessageRecord(
            message: reply.result.message,
            correlationID: reply.result.correlationID,
            status: reply.result.status,
            timezone: reply.period.timezone
        )
        try await dispatch("clinic-slot-approval", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: PushPayRunsMessageRecord, _ mesh: MeshClient) async throws {
        var write: (PushPayRunsMessageRecord) async throws -> Void = PushPayRunsMessageLogOnly().apply
        switch kind {
        case "patient-query":
            write = PushPayRunsMessagePatientQuery(client: Acme_Patients_V1_PatientQueryService.Client(wrapping: mesh)).apply
        case "access-policy-query":
            write = PushPayRunsMessageAccessPolicyQuery(client: Acme_Authorization_V1_AccessPolicyQueryService.Client(wrapping: mesh)).apply
        case "clinic-slot-approval":
            write = PushPayRunsMessageClinicSlotApproval(client: Acme_Appointments_V1_ClinicSlotApprovalService.Client(wrapping: mesh)).apply
        case "dispatch-order-query":
            write = PushPayRunsMessageDispatchOrderQuery(client: Acme_Dispatch_V1_DispatchOrderQueryService.Client(wrapping: mesh)).apply
        default:
            break
        }
        try await write(rec)
    }
}
