import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffProviderRulesMessage keeps of each GetProviderRules response.
struct HandOffProviderRulesMessageRecord {
    var message: String
    var status: String
    var providerID: String
}

/// Where HandOffProviderRulesMessage hands each record.
protocol HandOffProviderRulesMessageTarget {
    func push(_ rec: HandOffProviderRulesMessageRecord) async throws
}

/// Hands records to acme.careplans.v1.CarePlanValidationService.
struct HandOffProviderRulesMessageCarePlanValidation: HandOffProviderRulesMessageTarget {
    let client: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>

    func push(_ rec: HandOffProviderRulesMessageRecord) async throws {
        _ = try await client.validateCarePlan(.with {
            $0.carePlan.number = rec.message
        })
    }
}

/// Sends records to acme.datasets.v1.DatasetQueryService.
struct HandOffProviderRulesMessageDatasetQuery: HandOffProviderRulesMessageTarget {
    let client: Acme_Datasets_V1_DatasetQueryService.Client<MeshTransport>

    func push(_ rec: HandOffProviderRulesMessageRecord) async throws {
        _ = try await client.browseDatasets(.with {
            $0.filter.region = rec.status
            $0.orderBy = rec.message
            $0.filter.ownerID = rec.providerID
        })
    }
}

/// Sends records to acme.patientapp.v1.PatientHomeGatewayService.
struct HandOffProviderRulesMessagePatientHomeGateway: HandOffProviderRulesMessageTarget {
    let client: Acme_Patientapp_V1_PatientHomeGatewayService.Client<MeshTransport>

    func push(_ rec: HandOffProviderRulesMessageRecord) async throws {
        _ = try await client.getPatientHomeSummary(.with {
            $0.patientHomeID = rec.status
        })
    }
}

/// Reads acme.appointments.v1.ProviderValidationService/GetProviderRules and hands what it keeps to the sink of its kind.
enum HandOffProviderRulesMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Appointments_V1_ProviderValidationService.Client(wrapping: mesh)
        let response = try await reader.getProviderRules(.with { $0.providerID = "primary-hand-off-provider-rules-message" })
        let row = HandOffProviderRulesMessageRecord(
            message: response.result.message,
            status: response.result.status,
            providerID: response.provider.providerID
        )
        let sinks: [any HandOffProviderRulesMessageTarget] = [
            HandOffProviderRulesMessageCarePlanValidation(client: Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh)),
            HandOffProviderRulesMessageDatasetQuery(client: Acme_Datasets_V1_DatasetQueryService.Client(wrapping: mesh)),
            HandOffProviderRulesMessagePatientHomeGateway(client: Acme_Patientapp_V1_PatientHomeGatewayService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.push(row)
        }
    }
}
