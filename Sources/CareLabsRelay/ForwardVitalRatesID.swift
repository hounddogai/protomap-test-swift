import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardVitalRatesID keeps of each GetVitalRates response.
struct ForwardVitalRatesIDRecord {
    var vitalID: String
    var correlationID: String
}

/// Where ForwardVitalRatesID hands each record.
protocol ForwardVitalRatesIDDestination {
    func deliver(_ rec: ForwardVitalRatesIDRecord) async throws
}

/// Hands records to acme.patients.v1.PatientReportingService.
struct ForwardVitalRatesIDPatientReporting: ForwardVitalRatesIDDestination {
    let client: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>

    func deliver(_ rec: ForwardVitalRatesIDRecord) async throws {
        _ = try await client.generatePatientReport(.with {
            $0.reason = rec.correlationID
        })
    }
}

/// Hands records to acme.featureflags.v1.FeatureFlagQueryService.
struct ForwardVitalRatesIDFeatureFlagQuery: ForwardVitalRatesIDDestination {
    let client: Acme_Featureflags_V1_FeatureFlagQueryService.Client<MeshTransport>

    func deliver(_ rec: ForwardVitalRatesIDRecord) async throws {
        _ = try await client.browseFeatureFlags(.with {
            $0.filter.query = rec.vitalID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ForwardVitalRatesIDLogOnly: ForwardVitalRatesIDDestination {
    let logger = Logger(label: "acme.forward-vital-rates-id")

    func deliver(_ rec: ForwardVitalRatesIDRecord) async throws {
        logger.info("No sink for record", metadata: ["vitalID": .string(rec.vitalID)])
    }
}

/// Reads acme.careplans.v1.VitalCalculationService/GetVitalRates and hands what it keeps to the sink of its kind.
enum ForwardVitalRatesID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Careplans_V1_VitalCalculationService.Client(wrapping: mesh)
        let response = try await origin.getVitalRates(.with { $0.vitalID = "main-forward-vital-rates-id" })
        let entry = ForwardVitalRatesIDRecord(
            vitalID: response.vital.vitalID,
            correlationID: Kit.Text.normalize(response.vital.correlationID)
        )
        try await deliver("patient-reporting", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ForwardVitalRatesIDRecord, _ mesh: MeshClient) async throws {
        var sink: any ForwardVitalRatesIDDestination = ForwardVitalRatesIDLogOnly()
        switch kind {
        case "patient-reporting":
            sink = ForwardVitalRatesIDPatientReporting(client: Acme_Patients_V1_PatientReportingService.Client(wrapping: mesh))
        case "feature-flag-query":
            sink = ForwardVitalRatesIDFeatureFlagQuery(client: Acme_Featureflags_V1_FeatureFlagQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.deliver(rec)
    }
}
