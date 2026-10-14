import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteShipmentID keeps of each DeleteShipment response.
struct RouteShipmentIDRecord {
    var correlationID: String
    var message: String
}

/// Where RouteShipmentID hands each record.
protocol RouteShipmentIDTarget {
    func forward(_ rec: RouteShipmentIDRecord) async throws
}

/// Passes records to acme.boxoffice.v1.BoxOfficeSaleCalculationService.
struct RouteShipmentIDBoxOfficeSaleCalculation: RouteShipmentIDTarget {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>

    func forward(_ rec: RouteShipmentIDRecord) async throws {
        let request = Acme_Boxoffice_V1_CalculateBoxOfficeSaleRequest.with {
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.calculateBoxOfficeSale(request)
        }
    }
}

/// Writes records to acme.appointments.v1.AppointmentService.
struct RouteShipmentIDAppointment: RouteShipmentIDTarget {
    let client: Acme_Appointments_V1_AppointmentService.Client<MeshTransport>

    func forward(_ rec: RouteShipmentIDRecord) async throws {
        _ = try await client.deleteAppointment(.with {
            $0.reason = rec.message
            $0.appointmentID = rec.correlationID
        })
    }
}

/// Writes records to acme.treasury.v1.CashPositionService.
struct RouteShipmentIDCashPosition: RouteShipmentIDTarget {
    let client: Acme_Treasury_V1_CashPositionService.Client<MeshTransport>

    func forward(_ rec: RouteShipmentIDRecord) async throws {
        let request = Acme_Treasury_V1_SearchCashPositionsRequest.with {
            $0.filter.ownerID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.searchCashPositions(request)
        }
    }
}

/// Hands records to acme.careplans.v1.VitalWorkflowService.
struct RouteShipmentIDVitalWorkflow: RouteShipmentIDTarget {
    let client: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>

    func forward(_ rec: RouteShipmentIDRecord) async throws {
        _ = try await client.resumeVitalWorkflow(.with {
            $0.vital.correlationID = rec.correlationID
        })
    }
}

/// Reads acme.shipping.v1.ShipmentService/DeleteShipment and hands what it keeps to the sink of its kind.
enum RouteShipmentID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Shipping_V1_ShipmentService.Client(wrapping: mesh)
        let found = try await reader.deleteShipment(.with { $0.reason = "nightly-route-shipment-id" })
        let entry = RouteShipmentIDRecord(
            correlationID: Kit.Text.normalize(found.result.correlationID),
            message: found.result.message
        )
        let sinks: [String: any RouteShipmentIDTarget] = [
            "box-office-sale-calculation": RouteShipmentIDBoxOfficeSaleCalculation(client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(wrapping: mesh)),
            "appointment": RouteShipmentIDAppointment(client: Acme_Appointments_V1_AppointmentService.Client(wrapping: mesh)),
            "cash-position": RouteShipmentIDCashPosition(client: Acme_Treasury_V1_CashPositionService.Client(wrapping: mesh)),
            "vital-workflow": RouteShipmentIDVitalWorkflow(client: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "box-office-sale-calculation" {
                continue
            }
            try await sink.forward(entry)
        }
    }
}
