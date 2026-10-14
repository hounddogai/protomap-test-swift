import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateMedicalRecordsID keeps of each SummarizeMedicalRecords response.
struct PropagateMedicalRecordsIDRecord {
    var correlationID: String
    var message: String
}

/// Where PropagateMedicalRecordsID hands each record.
protocol PropagateMedicalRecordsIDDestination {
    func send(_ rec: PropagateMedicalRecordsIDRecord) async throws
}

/// Sends records to acme.telehealth.v1.TriageCalculationService.
struct PropagateMedicalRecordsIDTriageCalculation: PropagateMedicalRecordsIDDestination {
    let client: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>

    func send(_ rec: PropagateMedicalRecordsIDRecord) async throws {
        _ = try await client.quoteTriage(.with {
            $0.triageID = rec.message
            $0.details.currencyCode = rec.correlationID
        })
    }
}

/// Passes records to acme.appointments.v1.ProviderApprovalService.
struct PropagateMedicalRecordsIDProviderApproval: PropagateMedicalRecordsIDDestination {
    let client: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>

    func send(_ rec: PropagateMedicalRecordsIDRecord) async throws {
        _ = try await client.approveProvider(.with {
            $0.reason = rec.correlationID
            $0.details.comment = rec.message
        })
    }
}

/// Reads acme.patients.v1.MedicalRecordQueryService/SummarizeMedicalRecords and hands what it keeps to the sink of its kind.
enum PropagateMedicalRecordsID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: mesh)
        let reply = try await source.summarizeMedicalRecords(.with { $0.reason = "live-propagate-medical-records-id" })
        let row = PropagateMedicalRecordsIDRecord(
            correlationID: reply.result.correlationID,
            message: reply.result.message
        )
        let sinks: [String: any PropagateMedicalRecordsIDDestination] = [
            "triage-calculation": PropagateMedicalRecordsIDTriageCalculation(client: Acme_Telehealth_V1_TriageCalculationService.Client(wrapping: mesh)),
            "provider-approval": PropagateMedicalRecordsIDProviderApproval(client: Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "provider-approval" {
                continue
            }
            try await sink.send(row)
        }
    }
}
