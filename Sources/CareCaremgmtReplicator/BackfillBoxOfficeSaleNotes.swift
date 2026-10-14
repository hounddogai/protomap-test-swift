import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillBoxOfficeSaleNotes keeps of each CloneBoxOfficeSale response.
struct BackfillBoxOfficeSaleNotesRecord {
    var notes: String
    var boxOfficeSaleID: String
}

/// Passes records to acme.patients.v1.PatientValidationService.
struct BackfillBoxOfficeSaleNotesPatientValidation {
    let client: Acme_Patients_V1_PatientValidationService.Client<MeshTransport>

    func send(_ rec: BackfillBoxOfficeSaleNotesRecord) async throws {
        _ = try await client.checkPatientEligibility(.with {
            $0.patient.patientID = rec.boxOfficeSaleID
            $0.details.locale = rec.notes
        })
    }
}

/// Reads acme.boxoffice.v1.BoxOfficeSaleService/CloneBoxOfficeSale and hands what it keeps to acme.patients.v1.PatientValidationService.
enum BackfillBoxOfficeSaleNotes {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: mesh)
        let reply = try await origin.cloneBoxOfficeSale(.with { $0.requestID = "current-backfill-box-office-sale-notes" })
        let record = BackfillBoxOfficeSaleNotesRecord(
            notes: reply.boxOfficeSale.notes,
            boxOfficeSaleID: reply.boxOfficeSale.boxOfficeSaleID
        )
        try await BackfillBoxOfficeSaleNotesPatientValidation(client: Acme_Patients_V1_PatientValidationService.Client(wrapping: mesh)).send(record)
    }
}
