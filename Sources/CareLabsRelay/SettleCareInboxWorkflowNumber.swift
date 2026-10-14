import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleCareInboxWorkflowNumber keeps of each AdvanceCareInboxWorkflow response.
struct SettleCareInboxWorkflowNumberRecord {
    var number: String
    var careInboxID: String
    var status: String
}

/// Where SettleCareInboxWorkflowNumber hands each record.
protocol SettleCareInboxWorkflowNumberDestination {
    func push(_ rec: SettleCareInboxWorkflowNumberRecord) async throws
}

/// Passes records to acme.telehealth.v1.VideoVisitValidationService.
struct SettleCareInboxWorkflowNumberVideoVisitValidation: SettleCareInboxWorkflowNumberDestination {
    let client: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>

    func push(_ rec: SettleCareInboxWorkflowNumberRecord) async throws {
        _ = try await client.validateVideoVisit(.with {
            $0.videoVisit.videoVisitID = rec.careInboxID
            $0.videoVisit.title = rec.number
            $0.reason = rec.status
        })
    }
}

/// Writes records to acme.prescriptions.v1.RefillLifecycleService.
struct SettleCareInboxWorkflowNumberRefillLifecycle: SettleCareInboxWorkflowNumberDestination {
    let client: Acme_Prescriptions_V1_RefillLifecycleService.Client<MeshTransport>

    func push(_ rec: SettleCareInboxWorkflowNumberRecord) async throws {
        _ = try await client.renewRefill(.with {
            $0.refillID = rec.careInboxID
            $0.details.reasonCode = rec.status
        })
    }
}

/// Writes records to acme.shipping.v1.ShipmentService.
struct SettleCareInboxWorkflowNumberShipment: SettleCareInboxWorkflowNumberDestination {
    let client: Acme_Shipping_V1_ShipmentService.Client<MeshTransport>

    func push(_ rec: SettleCareInboxWorkflowNumberRecord) async throws {
        _ = try await client.listShipments(.with {
            $0.orderBy = rec.status
            $0.filter.ownerID = rec.number
        })
    }
}

/// Reads acme.patientapp.v1.CareInboxWorkflowService/AdvanceCareInboxWorkflow and hands what it keeps to the sink of its kind.
enum SettleCareInboxWorkflowNumber {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)
        let got = try await upstream.advanceCareInboxWorkflow(.with { $0.reason = "current-settle-care-inbox-workflow-number" })
        let record = SettleCareInboxWorkflowNumberRecord(
            number: got.careInbox.number,
            careInboxID: got.careInbox.careInboxID,
            status: got.outcome.status
        )
        let sinks: [any SettleCareInboxWorkflowNumberDestination] = [
            SettleCareInboxWorkflowNumberVideoVisitValidation(client: Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)),
            SettleCareInboxWorkflowNumberRefillLifecycle(client: Acme_Prescriptions_V1_RefillLifecycleService.Client(wrapping: mesh)),
            SettleCareInboxWorkflowNumberShipment(client: Acme_Shipping_V1_ShipmentService.Client(wrapping: mesh)),
        ]
        try await sinks[0].push(record)
    }
}
