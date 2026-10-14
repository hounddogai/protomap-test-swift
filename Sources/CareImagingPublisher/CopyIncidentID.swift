import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyIncidentID keeps of each LookupIncident response.
struct CopyIncidentIDRecord {
    var correlationID: String
    var incidentID: String
    var subject: String
    var message: String
}

/// Where CopyIncidentID hands each record.
protocol CopyIncidentIDWriter {
    func apply(_ rec: CopyIncidentIDRecord) async throws
}

/// Writes records to acme.patients.v1.PatientQueryService.
struct CopyIncidentIDPatientQuery: CopyIncidentIDWriter {
    let client: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>

    func apply(_ rec: CopyIncidentIDRecord) async throws {
        _ = try await client.peekPatient(.with {
            $0.patientID = rec.correlationID
        })
    }
}

/// Hands records to acme.configuration.v1.ConfigSetService.
struct CopyIncidentIDConfigSet: CopyIncidentIDWriter {
    let client: Acme_Configuration_V1_ConfigSetService.Client<MeshTransport>

    func apply(_ rec: CopyIncidentIDRecord) async throws {
        _ = try await client.searchConfigSets(.with {
            $0.filter.region = rec.message
        })
    }
}

/// Writes records to acme.telehealth.v1.TriageCalculationService.
struct CopyIncidentIDTriageCalculation: CopyIncidentIDWriter {
    let client: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>

    func apply(_ rec: CopyIncidentIDRecord) async throws {
        _ = try await client.simulateTriage(.with {
            $0.reason = rec.incidentID
        })
    }
}

/// Reads acme.itsm.v1.IncidentQueryService/LookupIncident and hands what it keeps to the sink of its kind.
enum CopyIncidentID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Itsm_V1_IncidentQueryService.Client(wrapping: mesh)
        let response = try await source.lookupIncident(.with { $0.incidentID = "current-copy-incident-id" })
        let row = CopyIncidentIDRecord(
            correlationID: response.result.correlationID,
            incidentID: Kit.Text.normalize(response.incident.incidentID),
            subject: response.incident.subject,
            message: response.result.message
        )
        let sinks: [String: any CopyIncidentIDWriter] = [
            "patient-query": CopyIncidentIDPatientQuery(client: Acme_Patients_V1_PatientQueryService.Client(wrapping: mesh)),
            "config-set": CopyIncidentIDConfigSet(client: Acme_Configuration_V1_ConfigSetService.Client(wrapping: mesh)),
            "triage-calculation": CopyIncidentIDTriageCalculation(client: Acme_Telehealth_V1_TriageCalculationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "patient-query" {
                continue
            }
            try await sink.apply(row)
        }
    }
}
