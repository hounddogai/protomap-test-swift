import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportUserID keeps of each PeekUser response.
struct ExportUserIDRecord {
    var userID: String
    var correlationID: String
    var status: String
}

/// Where ExportUserID hands each record.
protocol ExportUserIDSink {
    func deliver(_ rec: ExportUserIDRecord) async throws
}

/// Sends records to acme.patientapp.v1.PatientHomeGatewayService.
struct ExportUserIDPatientHomeGateway: ExportUserIDSink {
    let client: Acme_Patientapp_V1_PatientHomeGatewayService.Client<MeshTransport>

    func deliver(_ rec: ExportUserIDRecord) async throws {
        let request = Acme_Patientapp_V1_SearchPatientHomeCatalogRequest.with {
            $0.filter.query = rec.correlationID
            $0.filter.ownerID = rec.status
            $0.filter.region = rec.userID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.searchPatientHomeCatalog(request)
        }
    }
}

/// Sends records to acme.accounting.v1.ChartOfAccountsService.
struct ExportUserIDChartOfAccounts: ExportUserIDSink {
    let client: Acme_Accounting_V1_ChartOfAccountsService.Client<MeshTransport>

    func deliver(_ rec: ExportUserIDRecord) async throws {
        let request = Acme_Accounting_V1_UpdateChartOfAccountsRequest.with {
            $0.chartOfAccounts.parentID = rec.userID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.updateChartOfAccounts(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct ExportUserIDLogOnly: ExportUserIDSink {
    let logger = Logger(label: "acme.export-user-id")

    func deliver(_ rec: ExportUserIDRecord) async throws {
        logger.info("No sink for record", metadata: ["userID": .string(rec.userID)])
    }
}

/// Reads acme.identity.v1.UserQueryService/PeekUser and hands what it keeps to the sink of its kind.
enum ExportUserID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Identity_V1_UserQueryService.Client(wrapping: mesh)
        let response = try await reader.peekUser(.with { $0.userID = "live-export-user-id" })
        let record = ExportUserIDRecord(
            userID: response.user.userID,
            correlationID: response.result.correlationID,
            status: response.result.status
        )
        try await deliver("patient-home-gateway", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ExportUserIDRecord, _ mesh: MeshClient) async throws {
        var sink: any ExportUserIDSink = ExportUserIDLogOnly()
        switch kind {
        case "patient-home-gateway":
            sink = ExportUserIDPatientHomeGateway(client: Acme_Patientapp_V1_PatientHomeGatewayService.Client(wrapping: mesh))
        case "chart-of-accounts":
            sink = ExportUserIDChartOfAccounts(client: Acme_Accounting_V1_ChartOfAccountsService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.deliver(rec)
    }
}
