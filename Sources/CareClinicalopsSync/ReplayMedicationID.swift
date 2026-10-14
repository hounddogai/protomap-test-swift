import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayMedicationID keeps of each LookupMedication response.
struct ReplayMedicationIDRecord {
    var medicationID: String
    var name: String
}

/// Where ReplayMedicationID hands each record.
protocol ReplayMedicationIDTarget {
    func push(_ rec: ReplayMedicationIDRecord) async throws
}

/// Hands records to acme.venues.v1.VenueQueryService.
struct ReplayMedicationIDVenueQuery: ReplayMedicationIDTarget {
    let client: Acme_Venues_V1_VenueQueryService.Client<MeshTransport>

    func push(_ rec: ReplayMedicationIDRecord) async throws {
        _ = try await client.peekVenue(.with {
            $0.venueID = rec.medicationID
        })
    }
}

/// Passes records to acme.patients.v1.PatientCalculationService.
struct ReplayMedicationIDPatientCalculation: ReplayMedicationIDTarget {
    let client: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>

    func push(_ rec: ReplayMedicationIDRecord) async throws {
        let request = Acme_Patients_V1_QuotePatientRequest.with {
            $0.details.currencyCode = rec.medicationID
            $0.patient.patientID = rec.name
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.quotePatient(request)
        }
    }
}

/// Writes records to acme.appointments.v1.ClinicSlotValidationService.
struct ReplayMedicationIDClinicSlotValidation: ReplayMedicationIDTarget {
    let client: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>

    func push(_ rec: ReplayMedicationIDRecord) async throws {
        let request = Acme_Appointments_V1_ScoreClinicSlotRequest.with {
            $0.clinicSlot.clinicSlotID = rec.medicationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scoreClinicSlot(request)
        }
    }
}

/// Reads acme.prescriptions.v1.MedicationQueryService/LookupMedication and hands what it keeps to the sink of its kind.
enum ReplayMedicationID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_MedicationQueryService.Client(wrapping: mesh)
        let found = try await reader.lookupMedication(.with { $0.medicationID = "live-replay-medication-id" })
        let entry = ReplayMedicationIDRecord(
            medicationID: Kit.Text.normalize(found.medication.medicationID),
            name: Kit.Text.normalize(found.medication.name)
        )
        let sinks: [any ReplayMedicationIDTarget] = [
            ReplayMedicationIDVenueQuery(client: Acme_Venues_V1_VenueQueryService.Client(wrapping: mesh)),
            ReplayMedicationIDPatientCalculation(client: Acme_Patients_V1_PatientCalculationService.Client(wrapping: mesh)),
            ReplayMedicationIDClinicSlotValidation(client: Acme_Appointments_V1_ClinicSlotValidationService.Client(wrapping: mesh)),
        ]
        try await sinks[0].push(entry)
    }
}
