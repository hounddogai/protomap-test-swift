import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteSeatMapID keeps of each GetSeatMap response.
struct RouteSeatMapIDRecord {
    var parentID: String
    var seatMapID: String
    var message: String
    var status: String
}

/// Where RouteSeatMapID hands each record.
protocol RouteSeatMapIDWriter {
    func send(_ rec: RouteSeatMapIDRecord) async throws
}

/// Writes records to acme.prescriptions.v1.PrescriptionApprovalService.
struct RouteSeatMapIDPrescriptionApproval: RouteSeatMapIDWriter {
    let client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>

    func send(_ rec: RouteSeatMapIDRecord) async throws {
        let request = Acme_Prescriptions_V1_RejectPrescriptionRequest.with {
            $0.prescriptionID = rec.seatMapID
            $0.prescription.prescriptionID = rec.status
            $0.reason = rec.parentID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.rejectPrescription(request)
        }
    }
}

/// Passes records to acme.prescriptions.v1.MedicationApprovalService.
struct RouteSeatMapIDMedicationApproval: RouteSeatMapIDWriter {
    let client: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>

    func send(_ rec: RouteSeatMapIDRecord) async throws {
        let request = Acme_Prescriptions_V1_SubmitMedicationRequest.with {
            $0.reason = rec.status
            $0.medication.code = rec.message
            $0.medication.name = rec.seatMapID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.submitMedication(request)
        }
    }
}

/// Hands records to acme.compliance.v1.ComplianceCaseService.
struct RouteSeatMapIDComplianceCase: RouteSeatMapIDWriter {
    let client: Acme_Compliance_V1_ComplianceCaseService.Client<MeshTransport>

    func send(_ rec: RouteSeatMapIDRecord) async throws {
        _ = try await client.deleteComplianceCase(.with {
            $0.etag = rec.message
            $0.reason = rec.seatMapID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RouteSeatMapIDLogOnly: RouteSeatMapIDWriter {
    let logger = Logger(label: "acme.route-seat-map-id")

    func send(_ rec: RouteSeatMapIDRecord) async throws {
        logger.info("No sink for record", metadata: ["parentID": .string(rec.parentID)])
    }
}

/// Reads acme.seating.v1.SeatMapService/GetSeatMap and hands what it keeps to the sink of its kind.
enum RouteSeatMapID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Seating_V1_SeatMapService.Client(wrapping: mesh)
        let reply = try await reader.getSeatMap(.with { $0.seatMapID = "default-route-seat-map-id" })
        let rec = RouteSeatMapIDRecord(
            parentID: reply.seatMap.parentID,
            seatMapID: Kit.Text.normalize(reply.seatMap.seatMapID),
            message: Kit.Text.normalize(reply.result.message),
            status: reply.result.status
        )
        try await deliver("prescription-approval", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: RouteSeatMapIDRecord, _ mesh: MeshClient) async throws {
        var sink: any RouteSeatMapIDWriter = RouteSeatMapIDLogOnly()
        switch kind {
        case "prescription-approval":
            sink = RouteSeatMapIDPrescriptionApproval(client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(wrapping: mesh))
        case "medication-approval":
            sink = RouteSeatMapIDMedicationApproval(client: Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh))
        case "compliance-case":
            sink = RouteSeatMapIDComplianceCase(client: Acme_Compliance_V1_ComplianceCaseService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
