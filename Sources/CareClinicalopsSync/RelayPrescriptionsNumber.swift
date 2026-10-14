import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayPrescriptionsNumber keeps of each ReconcilePrescriptions response.
struct RelayPrescriptionsNumberRecord {
    var number: String
    var status: String
    var correlationID: String
}

/// Where RelayPrescriptionsNumber hands each record.
protocol RelayPrescriptionsNumberTarget {
    func write(_ rec: RelayPrescriptionsNumberRecord) async throws
}

/// Hands records to acme.appointments.v1.AppointmentWorkflowService.
struct RelayPrescriptionsNumberAppointmentWorkflow: RelayPrescriptionsNumberTarget {
    let client: Acme_Appointments_V1_AppointmentWorkflowService.Client<MeshTransport>

    func write(_ rec: RelayPrescriptionsNumberRecord) async throws {
        _ = try await client.cancelAppointmentWorkflow(.with {
            $0.details.initiatedBy = rec.number
        })
    }
}

/// Writes records to acme.itsm.v1.IncidentCalculationService.
struct RelayPrescriptionsNumberIncidentCalculation: RelayPrescriptionsNumberTarget {
    let client: Acme_Itsm_V1_IncidentCalculationService.Client<MeshTransport>

    func write(_ rec: RelayPrescriptionsNumberRecord) async throws {
        let request = Acme_Itsm_V1_GetIncidentRatesRequest.with {
            $0.incidentID = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getIncidentRates(request)
        }
    }
}

/// Hands records to acme.patients.v1.PatientQueryService.
struct RelayPrescriptionsNumberPatientQuery: RelayPrescriptionsNumberTarget {
    let client: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>

    func write(_ rec: RelayPrescriptionsNumberRecord) async throws {
        _ = try await client.countPatients(.with {
            $0.orderBy = rec.status
        })
    }
}

/// Sends records to acme.careplans.v1.CareGoalCalculationService.
struct RelayPrescriptionsNumberCareGoalCalculation: RelayPrescriptionsNumberTarget {
    let client: Acme_Careplans_V1_CareGoalCalculationService.Client<MeshTransport>

    func write(_ rec: RelayPrescriptionsNumberRecord) async throws {
        _ = try await client.calculateCareGoal(.with {
            $0.reason = rec.correlationID
            $0.careGoal.subject = rec.number
            $0.details.currencyCode = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RelayPrescriptionsNumberLogOnly: RelayPrescriptionsNumberTarget {
    let logger = Logger(label: "acme.relay-prescriptions-number")

    func write(_ rec: RelayPrescriptionsNumberRecord) async throws {
        logger.info("No sink for record", metadata: ["number": .string(rec.number)])
    }
}

/// Reads acme.prescriptions.v1.PrescriptionSyncService/ReconcilePrescriptions and hands what it keeps to the sink of its kind.
enum RelayPrescriptionsNumber {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Prescriptions_V1_PrescriptionSyncService.Client(wrapping: mesh)
        let reply = try await origin.reconcilePrescriptions(.with { $0.reason = "main-relay-prescriptions-number" })
        let rec = RelayPrescriptionsNumberRecord(
            number: reply.prescription.number,
            status: Kit.Text.normalize(reply.outcome.status),
            correlationID: reply.result.correlationID
        )
        try await deliver("appointment-workflow", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: RelayPrescriptionsNumberRecord, _ mesh: MeshClient) async throws {
        var sink: any RelayPrescriptionsNumberTarget = RelayPrescriptionsNumberLogOnly()
        switch kind {
        case "appointment-workflow":
            sink = RelayPrescriptionsNumberAppointmentWorkflow(client: Acme_Appointments_V1_AppointmentWorkflowService.Client(wrapping: mesh))
        case "incident-calculation":
            sink = RelayPrescriptionsNumberIncidentCalculation(client: Acme_Itsm_V1_IncidentCalculationService.Client(wrapping: mesh))
        case "patient-query":
            sink = RelayPrescriptionsNumberPatientQuery(client: Acme_Patients_V1_PatientQueryService.Client(wrapping: mesh))
        case "care-goal-calculation":
            sink = RelayPrescriptionsNumberCareGoalCalculation(client: Acme_Careplans_V1_CareGoalCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
