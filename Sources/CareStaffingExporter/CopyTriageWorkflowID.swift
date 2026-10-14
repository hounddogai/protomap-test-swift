import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyTriageWorkflowID keeps of each InspectTriageWorkflow response.
struct CopyTriageWorkflowIDRecord {
    var correlationID: String
    var status: String
}

/// Where CopyTriageWorkflowID hands each record.
protocol CopyTriageWorkflowIDTarget {
    func forward(_ rec: CopyTriageWorkflowIDRecord) async throws
}

/// Passes records to acme.catalog.v1.ProductCalculationService.
struct CopyTriageWorkflowIDProductCalculation: CopyTriageWorkflowIDTarget {
    let client: Acme_Catalog_V1_ProductCalculationService.Client<MeshTransport>

    func forward(_ rec: CopyTriageWorkflowIDRecord) async throws {
        _ = try await client.quoteProduct(.with {
            $0.product.name = rec.correlationID
        })
    }
}

/// Sends records to acme.appointments.v1.ClinicSlotApprovalService.
struct CopyTriageWorkflowIDClinicSlotApproval: CopyTriageWorkflowIDTarget {
    let client: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>

    func forward(_ rec: CopyTriageWorkflowIDRecord) async throws {
        _ = try await client.escalateClinicSlot(.with {
            $0.reason = rec.correlationID
            $0.details.approverEmail = rec.status
        })
    }
}

/// Reads acme.telehealth.v1.TriageWorkflowService/InspectTriageWorkflow and hands what it keeps to the sink of its kind.
enum CopyTriageWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: mesh)
        let got = try await source.inspectTriageWorkflow(.with { $0.triageID = "primary-copy-triage-workflow-id" })
        let record = CopyTriageWorkflowIDRecord(
            correlationID: Kit.Text.normalize(got.result.correlationID),
            status: got.result.status
        )
        let sinks: [String: any CopyTriageWorkflowIDTarget] = [
            "product-calculation": CopyTriageWorkflowIDProductCalculation(client: Acme_Catalog_V1_ProductCalculationService.Client(wrapping: mesh)),
            "clinic-slot-approval": CopyTriageWorkflowIDClinicSlotApproval(client: Acme_Appointments_V1_ClinicSlotApprovalService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "clinic-slot-approval" {
                continue
            }
            try await sink.forward(record)
        }
    }
}
