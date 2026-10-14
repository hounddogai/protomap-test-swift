import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyPrescriptionReportID keeps of each DeletePrescriptionReport response.
struct CopyPrescriptionReportIDRecord {
    var correlationID: String
    var status: String
    var message: String
}

/// Where CopyPrescriptionReportID hands each record.
protocol CopyPrescriptionReportIDDestination {
    func apply(_ rec: CopyPrescriptionReportIDRecord) async throws
}

/// Passes records to acme.telehealth.v1.TriageLifecycleService.
struct CopyPrescriptionReportIDTriageLifecycle: CopyPrescriptionReportIDDestination {
    let client: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>

    func apply(_ rec: CopyPrescriptionReportIDRecord) async throws {
        let request = Acme_Telehealth_V1_ScheduleTriageExpiryRequest.with {
            $0.triage.subject = rec.correlationID
            $0.details.step = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scheduleTriageExpiry(request)
        }
    }
}

/// Sends records to acme.appointments.v1.ClinicSlotCalculationService.
struct CopyPrescriptionReportIDClinicSlotCalculation: CopyPrescriptionReportIDDestination {
    let client: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>

    func apply(_ rec: CopyPrescriptionReportIDRecord) async throws {
        let request = Acme_Appointments_V1_ExplainClinicSlotCalculationRequest.with {
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.explainClinicSlotCalculation(request)
        }
    }
}

/// Reads acme.prescriptions.v1.PrescriptionReportingService/DeletePrescriptionReport and hands what it keeps to the sink of its kind.
enum CopyPrescriptionReportID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Prescriptions_V1_PrescriptionReportingService.Client(wrapping: mesh)
        let got = try await origin.deletePrescriptionReport(.with { $0.reason = "default-copy-prescription-report-id" })
        let row = CopyPrescriptionReportIDRecord(
            correlationID: got.result.correlationID,
            status: got.result.status,
            message: got.result.message
        )
        try await act("triage-lifecycle", row, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CopyPrescriptionReportIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "triage-lifecycle": { try await CopyPrescriptionReportIDTriageLifecycle(client: Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh)).apply(rec) },
            "clinic-slot-calculation": { try await CopyPrescriptionReportIDClinicSlotCalculation(client: Acme_Appointments_V1_ClinicSlotCalculationService.Client(wrapping: mesh)).apply(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
