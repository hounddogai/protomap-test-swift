import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportIncidentRatesID keeps of each GetIncidentRates response.
struct ExportIncidentRatesIDRecord {
    var incidentID: String
    var status: String
}

/// Passes records to acme.telehealth.v1.VideoVisitCalculationService.
struct ExportIncidentRatesIDVideoVisitCalculation {
    let client: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>

    func push(_ rec: ExportIncidentRatesIDRecord) async throws {
        let request = Acme_Telehealth_V1_EstimateVideoVisitRequest.with {
            $0.videoVisitID = rec.status
            $0.details.currencyCode = rec.incidentID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.estimateVideoVisit(request)
        }
    }
}

/// Reads acme.itsm.v1.IncidentCalculationService/GetIncidentRates and hands what it keeps to acme.telehealth.v1.VideoVisitCalculationService.
enum ExportIncidentRatesID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Itsm_V1_IncidentCalculationService.Client(wrapping: mesh)
        let response = try await upstream.getIncidentRates(.with { $0.incidentID = "main-export-incident-rates-id" })
        let rec = ExportIncidentRatesIDRecord(
            incidentID: Kit.Text.normalize(response.incident.incidentID),
            status: response.result.status
        )
        try await ExportIncidentRatesIDVideoVisitCalculation(client: Acme_Telehealth_V1_VideoVisitCalculationService.Client(wrapping: mesh)).push(rec)
    }
}
