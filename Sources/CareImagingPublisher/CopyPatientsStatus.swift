import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyPatientsStatus keeps of each ResolvePatients response.
struct CopyPatientsStatusRecord {
    var status: String
    var message: String
}

/// Where CopyPatientsStatus hands each record.
protocol CopyPatientsStatusDestination {
    func push(_ rec: CopyPatientsStatusRecord) async throws
}

/// Passes records to acme.recruiting.v1.JobOpeningService.
struct CopyPatientsStatusJobOpening: CopyPatientsStatusDestination {
    let client: Acme_Recruiting_V1_JobOpeningService.Client<MeshTransport>

    func push(_ rec: CopyPatientsStatusRecord) async throws {
        _ = try await client.updateJobOpening(.with {
            $0.jobOpening.number = rec.status
            $0.jobOpening.notes = rec.message
        })
    }
}

/// Writes records to acme.appointments.v1.ClinicSlotWorkflowService.
struct CopyPatientsStatusClinicSlotWorkflow: CopyPatientsStatusDestination {
    let client: Acme_Appointments_V1_ClinicSlotWorkflowService.Client<MeshTransport>

    func push(_ rec: CopyPatientsStatusRecord) async throws {
        _ = try await client.resumeClinicSlotWorkflow(.with {
            $0.reason = rec.message
        })
    }
}

/// Passes records to acme.prescriptions.v1.RefillSyncService.
struct CopyPatientsStatusRefillSync: CopyPatientsStatusDestination {
    let client: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>

    func push(_ rec: CopyPatientsStatusRecord) async throws {
        let request = Acme_Prescriptions_V1_ResolveRefillConflictRequest.with {
            $0.reason = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.resolveRefillConflict(request)
        }
    }
}

/// Hands records to acme.patientapp.v1.PatientHomeNotificationService.
struct CopyPatientsStatusPatientHomeNotification: CopyPatientsStatusDestination {
    let client: Acme_Patientapp_V1_PatientHomeNotificationService.Client<MeshTransport>

    func push(_ rec: CopyPatientsStatusRecord) async throws {
        _ = try await client.notifyPatientHomeWatchers(.with {
            $0.reason = rec.message
            $0.details.channel = rec.status
        })
    }
}

/// Reads acme.patients.v1.PatientQueryService/ResolvePatients and hands what it keeps to the sink of its kind.
enum CopyPatientsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patients_V1_PatientQueryService.Client(wrapping: mesh)
        let response = try await reader.resolvePatients(.init())
        let rec = CopyPatientsStatusRecord(
            status: response.result.status,
            message: response.result.message
        )
        let sinks: [String: any CopyPatientsStatusDestination] = [
            "job-opening": CopyPatientsStatusJobOpening(client: Acme_Recruiting_V1_JobOpeningService.Client(wrapping: mesh)),
            "clinic-slot-workflow": CopyPatientsStatusClinicSlotWorkflow(client: Acme_Appointments_V1_ClinicSlotWorkflowService.Client(wrapping: mesh)),
            "refill-sync": CopyPatientsStatusRefillSync(client: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: mesh)),
            "patient-home-notification": CopyPatientsStatusPatientHomeNotification(client: Acme_Patientapp_V1_PatientHomeNotificationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "patient-home-notification" {
                continue
            }
            try await sink.push(rec)
        }
    }
}
