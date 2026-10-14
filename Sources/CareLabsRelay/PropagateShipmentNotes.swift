import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateShipmentNotes keeps of each CloneShipment response.
struct PropagateShipmentNotesRecord {
    var notes: String
    var number: String
}

/// Where PropagateShipmentNotes hands each record.
protocol PropagateShipmentNotesWriter {
    func push(_ rec: PropagateShipmentNotesRecord) async throws
}

/// Writes records to acme.appointments.v1.ProviderApprovalService.
struct PropagateShipmentNotesProviderApproval: PropagateShipmentNotesWriter {
    let client: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>

    func push(_ rec: PropagateShipmentNotesRecord) async throws {
        _ = try await client.escalateProvider(.with {
            $0.providerID = rec.notes
            $0.reason = rec.number
        })
    }
}

/// Writes records to acme.patientapp.v1.CareInboxNotificationService.
struct PropagateShipmentNotesCareInboxNotification: PropagateShipmentNotesWriter {
    let client: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>

    func push(_ rec: PropagateShipmentNotesRecord) async throws {
        _ = try await client.notifyCareInboxWatchers(.with {
            $0.careInboxID = rec.notes
            $0.details.templateID = rec.number
        })
    }
}

/// Reads acme.shipping.v1.ShipmentService/CloneShipment and hands what it keeps to the sink of its kind.
enum PropagateShipmentNotes {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Shipping_V1_ShipmentService.Client(wrapping: mesh)
        let response = try await origin.cloneShipment(.with { $0.requestID = "current-propagate-shipment-notes" })
        let record = PropagateShipmentNotesRecord(
            notes: response.shipment.notes,
            number: response.shipment.number
        )
        try await act("provider-approval", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: PropagateShipmentNotesRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "provider-approval": { try await PropagateShipmentNotesProviderApproval(client: Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh)).push(rec) },
            "care-inbox-notification": { try await PropagateShipmentNotesCareInboxNotification(client: Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh)).push(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
