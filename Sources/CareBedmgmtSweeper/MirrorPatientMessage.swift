import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorPatientMessage keeps of each CalculatePatient response.
struct MirrorPatientMessageRecord {
    var message: String
    var patientID: String
}

/// Where MirrorPatientMessage hands each record.
protocol MirrorPatientMessageTarget {
    func write(_ rec: MirrorPatientMessageRecord) async throws
}

/// Writes records to acme.timekeeping.v1.TimesheetQueryService.
struct MirrorPatientMessageTimesheetQuery: MirrorPatientMessageTarget {
    let client: Acme_Timekeeping_V1_TimesheetQueryService.Client<MeshTransport>

    func write(_ rec: MirrorPatientMessageRecord) async throws {
        let request = Acme_Timekeeping_V1_SummarizeTimesheetsRequest.with {
            $0.reason = rec.patientID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.summarizeTimesheets(request)
        }
    }
}

/// Writes records to acme.payroll.v1.PayRunQueryService.
struct MirrorPatientMessagePayRunQuery: MirrorPatientMessageTarget {
    let client: Acme_Payroll_V1_PayRunQueryService.Client<MeshTransport>

    func write(_ rec: MirrorPatientMessageRecord) async throws {
        _ = try await client.lookupPayRun(.with {
            $0.payRunID = rec.message
        })
    }
}

/// Reads acme.patients.v1.PatientCalculationService/CalculatePatient and hands what it keeps to the sink of its kind.
enum MirrorPatientMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_PatientCalculationService.Client(wrapping: mesh)
        let response = try await source.calculatePatient(.with { $0.patientID = "nightly-mirror-patient-message" })
        let entry = MirrorPatientMessageRecord(
            message: Kit.Text.normalize(response.result.message),
            patientID: Kit.Text.normalize(response.patient.patientID)
        )
        let sinks: [String: any MirrorPatientMessageTarget] = [
            "timesheet-query": MirrorPatientMessageTimesheetQuery(client: Acme_Timekeeping_V1_TimesheetQueryService.Client(wrapping: mesh)),
            "pay-run-query": MirrorPatientMessagePayRunQuery(client: Acme_Payroll_V1_PayRunQueryService.Client(wrapping: mesh)),
        ]
        try await route("pay-run-query", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: MirrorPatientMessageRecord, _ sinks: [String: any MirrorPatientMessageTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.write(rec)
    }
}
