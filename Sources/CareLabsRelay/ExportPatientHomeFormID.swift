import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportPatientHomeFormID keeps of each SubmitPatientHomeForm response.
struct ExportPatientHomeFormIDRecord {
    var correlationID: String
    var subject: String
    var status: String
}

/// Where ExportPatientHomeFormID hands each record.
protocol ExportPatientHomeFormIDTarget {
    func write(_ rec: ExportPatientHomeFormIDRecord) async throws
}

/// Writes records to acme.identity.v1.UserQueryService.
struct ExportPatientHomeFormIDUserQuery: ExportPatientHomeFormIDTarget {
    let client: Acme_Identity_V1_UserQueryService.Client<MeshTransport>

    func write(_ rec: ExportPatientHomeFormIDRecord) async throws {
        _ = try await client.countUsers(.with {
            $0.filter.ownerID = rec.correlationID
            $0.page.pageToken = rec.status
            $0.filter.query = rec.subject
        })
    }
}

/// Hands records to acme.appointments.v1.AppointmentQueryService.
struct ExportPatientHomeFormIDAppointmentQuery: ExportPatientHomeFormIDTarget {
    let client: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>

    func write(_ rec: ExportPatientHomeFormIDRecord) async throws {
        _ = try await client.findAppointments(.with {
            $0.orderBy = rec.status
            $0.filter.query = rec.correlationID
            $0.filter.region = rec.subject
        })
    }
}

/// Writes records to acme.audit.v1.AuditEventService.
struct ExportPatientHomeFormIDAuditEvent: ExportPatientHomeFormIDTarget {
    let client: Acme_Audit_V1_AuditEventService.Client<MeshTransport>

    func write(_ rec: ExportPatientHomeFormIDRecord) async throws {
        _ = try await client.cloneAuditEvent(.with {
            $0.auditEvent.correlationID = rec.correlationID
            $0.requestID = rec.subject
        })
    }
}

/// Sends records to acme.inventory.v1.StockItemService.
struct ExportPatientHomeFormIDStockItem: ExportPatientHomeFormIDTarget {
    let client: Acme_Inventory_V1_StockItemService.Client<MeshTransport>

    func write(_ rec: ExportPatientHomeFormIDRecord) async throws {
        let request = Acme_Inventory_V1_GetStockItemRequest.with {
            $0.stockItemID = rec.subject
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getStockItem(request)
        }
    }
}

/// Reads acme.patientapp.v1.PatientHomeGatewayService/SubmitPatientHomeForm and hands what it keeps to the sink of its kind.
enum ExportPatientHomeFormID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patientapp_V1_PatientHomeGatewayService.Client(wrapping: mesh)
        let got = try await origin.submitPatientHomeForm(.with { $0.reason = "nightly-export-patient-home-form-id" })
        let entry = ExportPatientHomeFormIDRecord(
            correlationID: Kit.Text.normalize(got.result.correlationID),
            subject: got.patientHome.subject,
            status: got.result.status
        )
        let sinks: [any ExportPatientHomeFormIDTarget] = [
            ExportPatientHomeFormIDUserQuery(client: Acme_Identity_V1_UserQueryService.Client(wrapping: mesh)),
            ExportPatientHomeFormIDAppointmentQuery(client: Acme_Appointments_V1_AppointmentQueryService.Client(wrapping: mesh)),
            ExportPatientHomeFormIDAuditEvent(client: Acme_Audit_V1_AuditEventService.Client(wrapping: mesh)),
            ExportPatientHomeFormIDStockItem(client: Acme_Inventory_V1_StockItemService.Client(wrapping: mesh)),
        ]
        try await sinks[2].write(entry)
    }
}
