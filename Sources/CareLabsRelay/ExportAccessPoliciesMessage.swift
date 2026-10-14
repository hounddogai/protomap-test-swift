import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportAccessPoliciesMessage keeps of each ResolveAccessPolicies response.
struct ExportAccessPoliciesMessageRecord {
    var message: String
    var status: String
}

/// Where ExportAccessPoliciesMessage hands each record.
protocol ExportAccessPoliciesMessageSink {
    func apply(_ rec: ExportAccessPoliciesMessageRecord) async throws
}

/// Hands records to acme.appointments.v1.ClinicSlotApprovalService.
struct ExportAccessPoliciesMessageClinicSlotApproval: ExportAccessPoliciesMessageSink {
    let client: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>

    func apply(_ rec: ExportAccessPoliciesMessageRecord) async throws {
        let request = Acme_Appointments_V1_EscalateClinicSlotRequest.with {
            $0.clinicSlotID = rec.message
            $0.reason = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.escalateClinicSlot(request)
        }
    }
}

/// Writes records to acme.catalog.v1.ProductCalculationService.
struct ExportAccessPoliciesMessageProductCalculation: ExportAccessPoliciesMessageSink {
    let client: Acme_Catalog_V1_ProductCalculationService.Client<MeshTransport>

    func apply(_ rec: ExportAccessPoliciesMessageRecord) async throws {
        let request = Acme_Catalog_V1_ExplainProductCalculationRequest.with {
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.explainProductCalculation(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct ExportAccessPoliciesMessageLogOnly: ExportAccessPoliciesMessageSink {
    let logger = Logger(label: "acme.export-access-policies-message")

    func apply(_ rec: ExportAccessPoliciesMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.authorization.v1.AccessPolicyQueryService/ResolveAccessPolicies and hands what it keeps to the sink of its kind.
enum ExportAccessPoliciesMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Authorization_V1_AccessPolicyQueryService.Client(wrapping: mesh)
        let reply = try await origin.resolveAccessPolicies(.init())
        let row = ExportAccessPoliciesMessageRecord(
            message: reply.result.message,
            status: reply.result.status
        )
        try await dispatch("clinic-slot-approval", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: ExportAccessPoliciesMessageRecord, _ mesh: MeshClient) async throws {
        var write: (ExportAccessPoliciesMessageRecord) async throws -> Void = ExportAccessPoliciesMessageLogOnly().apply
        switch kind {
        case "clinic-slot-approval":
            write = ExportAccessPoliciesMessageClinicSlotApproval(client: Acme_Appointments_V1_ClinicSlotApprovalService.Client(wrapping: mesh)).apply
        case "product-calculation":
            write = ExportAccessPoliciesMessageProductCalculation(client: Acme_Catalog_V1_ProductCalculationService.Client(wrapping: mesh)).apply
        default:
            break
        }
        try await write(rec)
    }
}
