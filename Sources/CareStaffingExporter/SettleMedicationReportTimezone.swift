import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleMedicationReportTimezone keeps of each ScheduleMedicationReport response.
struct SettleMedicationReportTimezoneRecord {
    var timezone: String
    var reportID: String
    var downloadUri: String
}

/// Where SettleMedicationReportTimezone hands each record.
protocol SettleMedicationReportTimezoneSink {
    func deliver(_ rec: SettleMedicationReportTimezoneRecord) async throws
}

/// Sends records to acme.careplans.v1.CarePlanValidationService.
struct SettleMedicationReportTimezoneCarePlanValidation: SettleMedicationReportTimezoneSink {
    let client: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>

    func deliver(_ rec: SettleMedicationReportTimezoneRecord) async throws {
        _ = try await client.lintCarePlans(.with {
            $0.reason = rec.reportID
            $0.details.locale = rec.downloadUri
            $0.carePlanID = rec.timezone
        })
    }
}

/// Passes records to acme.appointments.v1.ProviderQueryService.
struct SettleMedicationReportTimezoneProviderQuery: SettleMedicationReportTimezoneSink {
    let client: Acme_Appointments_V1_ProviderQueryService.Client<MeshTransport>

    func deliver(_ rec: SettleMedicationReportTimezoneRecord) async throws {
        let request = Acme_Appointments_V1_LookupProviderRequest.with {
            $0.providerID = rec.downloadUri
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lookupProvider(request)
        }
    }
}

/// Reads acme.prescriptions.v1.MedicationReportingService/ScheduleMedicationReport and hands what it keeps to the sink of its kind.
enum SettleMedicationReportTimezone {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_MedicationReportingService.Client(wrapping: mesh)
        let found = try await upstream.scheduleMedicationReport(.with { $0.reason = "nightly-settle-medication-report-timezone" })
        let row = SettleMedicationReportTimezoneRecord(
            timezone: Kit.Text.normalize(found.period.timezone),
            reportID: found.reportID,
            downloadUri: found.downloadUri
        )
        let sinks: [String: any SettleMedicationReportTimezoneSink] = [
            "care-plan-validation": SettleMedicationReportTimezoneCarePlanValidation(client: Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh)),
            "provider-query": SettleMedicationReportTimezoneProviderQuery(client: Acme_Appointments_V1_ProviderQueryService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "care-plan-validation" {
                continue
            }
            try await sink.deliver(row)
        }
    }
}
