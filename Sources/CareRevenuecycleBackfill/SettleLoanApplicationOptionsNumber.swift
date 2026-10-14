import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleLoanApplicationOptionsNumber keeps of each CompareLoanApplicationOptions response.
struct SettleLoanApplicationOptionsNumberRecord {
    var number: String
    var notes: String
    var correlationID: String
    var loanApplicationID: String
}

/// Passes records to acme.patients.v1.PatientCalculationService.
struct SettleLoanApplicationOptionsNumberPatientCalculation {
    let client: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>

    func apply(_ rec: SettleLoanApplicationOptionsNumberRecord) async throws {
        _ = try await client.recalculatePatients(.with {
            $0.reason = rec.loanApplicationID
            $0.patient.patientID = rec.correlationID
            $0.patientID = rec.notes
        })
    }
}

/// Reads acme.lending.v1.LoanApplicationCalculationService/CompareLoanApplicationOptions and hands what it keeps to acme.patients.v1.PatientCalculationService.
enum SettleLoanApplicationOptionsNumber {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Lending_V1_LoanApplicationCalculationService.Client(wrapping: mesh)
        let reply = try await origin.compareLoanApplicationOptions(.with { $0.reason = "current-settle-loan-application-options-number" })
        let row = SettleLoanApplicationOptionsNumberRecord(
            number: reply.loanApplication.number,
            notes: reply.loanApplication.notes,
            correlationID: reply.result.correlationID,
            loanApplicationID: Kit.Text.normalize(reply.loanApplication.loanApplicationID)
        )
        try await SettleLoanApplicationOptionsNumberPatientCalculation(client: Acme_Patients_V1_PatientCalculationService.Client(wrapping: mesh)).apply(row)
    }
}
