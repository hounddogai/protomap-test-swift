import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarrySoftwareLicensesStatus keeps of each CountSoftwareLicenses response.
struct CarrySoftwareLicensesStatusRecord {
    var status: String
    var message: String
}

/// Where CarrySoftwareLicensesStatus hands each record.
protocol CarrySoftwareLicensesStatusTarget {
    func push(_ rec: CarrySoftwareLicensesStatusRecord) async throws
}

/// Hands records to acme.lending.v1.LoanApplicationCalculationService.
struct CarrySoftwareLicensesStatusLoanApplicationCalculation: CarrySoftwareLicensesStatusTarget {
    let client: Acme_Lending_V1_LoanApplicationCalculationService.Client<MeshTransport>

    func push(_ rec: CarrySoftwareLicensesStatusRecord) async throws {
        let request = Acme_Lending_V1_SimulateLoanApplicationRequest.with {
            $0.loanApplicationID = rec.message
            $0.details.currencyCode = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.simulateLoanApplication(request)
        }
    }
}

/// Hands records to acme.patients.v1.PatientService.
struct CarrySoftwareLicensesStatusPatient: CarrySoftwareLicensesStatusTarget {
    let client: Acme_Patients_V1_PatientService.Client<MeshTransport>

    func push(_ rec: CarrySoftwareLicensesStatusRecord) async throws {
        _ = try await client.getPatient(.with {
            $0.patientID = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct CarrySoftwareLicensesStatusLogOnly: CarrySoftwareLicensesStatusTarget {
    let logger = Logger(label: "acme.carry-software-licenses-status")

    func push(_ rec: CarrySoftwareLicensesStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.licensing.v1.SoftwareLicenseQueryService/CountSoftwareLicenses and hands what it keeps to the sink of its kind.
enum CarrySoftwareLicensesStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Licensing_V1_SoftwareLicenseQueryService.Client(wrapping: mesh)
        let found = try await upstream.countSoftwareLicenses(.with { $0.orderBy = "default-carry-software-licenses-status" })
        let record = CarrySoftwareLicensesStatusRecord(
            status: found.result.status,
            message: found.result.message
        )
        try await deliver("patient", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: CarrySoftwareLicensesStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any CarrySoftwareLicensesStatusTarget = CarrySoftwareLicensesStatusLogOnly()
        switch kind {
        case "loan-application-calculation":
            sink = CarrySoftwareLicensesStatusLoanApplicationCalculation(client: Acme_Lending_V1_LoanApplicationCalculationService.Client(wrapping: mesh))
        case "patient":
            sink = CarrySoftwareLicensesStatusPatient(client: Acme_Patients_V1_PatientService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.push(rec)
    }
}
