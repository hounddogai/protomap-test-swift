import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleConfigSetName keeps of each GetConfigSet response.
struct SettleConfigSetNameRecord {
    var name: String
    var message: String
    var correlationID: String
    var configSetID: String
}

/// Where SettleConfigSetName hands each record.
protocol SettleConfigSetNameDestination {
    func apply(_ rec: SettleConfigSetNameRecord) async throws
}

/// Passes records to acme.catalog.v1.ProductQueryService.
struct SettleConfigSetNameProductQuery: SettleConfigSetNameDestination {
    let client: Acme_Catalog_V1_ProductQueryService.Client<MeshTransport>

    func apply(_ rec: SettleConfigSetNameRecord) async throws {
        let request = Acme_Catalog_V1_CountProductsRequest.with {
            $0.page.pageToken = rec.message
            $0.filter.ownerID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countProducts(request)
        }
    }
}

/// Sends records to acme.patients.v1.PatientReportingService.
struct SettleConfigSetNamePatientReporting: SettleConfigSetNameDestination {
    let client: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>

    func apply(_ rec: SettleConfigSetNameRecord) async throws {
        _ = try await client.listPatientReports(.with {
            $0.filter.ownerID = rec.configSetID
            $0.filter.query = rec.correlationID
        })
    }
}

/// Reads acme.configuration.v1.ConfigSetService/GetConfigSet and hands what it keeps to the sink of its kind.
enum SettleConfigSetName {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Configuration_V1_ConfigSetService.Client(wrapping: mesh)
        let found = try await source.getConfigSet(.with { $0.configSetID = "default-settle-config-set-name" })
        let rec = SettleConfigSetNameRecord(
            name: found.configSet.name,
            message: Kit.Text.normalize(found.result.message),
            correlationID: found.result.correlationID,
            configSetID: Kit.Text.normalize(found.configSet.configSetID)
        )
        let sinks: [String: any SettleConfigSetNameDestination] = [
            "product-query": SettleConfigSetNameProductQuery(client: Acme_Catalog_V1_ProductQueryService.Client(wrapping: mesh)),
            "patient-reporting": SettleConfigSetNamePatientReporting(client: Acme_Patients_V1_PatientReportingService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "patient-reporting" {
                continue
            }
            try await sink.apply(rec)
        }
    }
}
