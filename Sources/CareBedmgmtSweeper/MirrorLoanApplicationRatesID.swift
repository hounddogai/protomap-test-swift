import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorLoanApplicationRatesID keeps of each GetLoanApplicationRates response.
struct MirrorLoanApplicationRatesIDRecord {
    var correlationID: String
    var status: String
}

/// Where MirrorLoanApplicationRatesID hands each record.
protocol MirrorLoanApplicationRatesIDDestination {
    func deliver(_ rec: MirrorLoanApplicationRatesIDRecord) async throws
}

/// Passes records to acme.compliance.v1.ComplianceCaseService.
struct MirrorLoanApplicationRatesIDComplianceCase: MirrorLoanApplicationRatesIDDestination {
    let client: Acme_Compliance_V1_ComplianceCaseService.Client<MeshTransport>

    func deliver(_ rec: MirrorLoanApplicationRatesIDRecord) async throws {
        let request = Acme_Compliance_V1_DeleteComplianceCaseRequest.with {
            $0.complianceCaseID = rec.correlationID
            $0.etag = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.deleteComplianceCase(request)
        }
    }
}

/// Sends records to acme.patients.v1.MedicalRecordLifecycleService.
struct MirrorLoanApplicationRatesIDMedicalRecordLifecycle: MirrorLoanApplicationRatesIDDestination {
    let client: Acme_Patients_V1_MedicalRecordLifecycleService.Client<MeshTransport>

    func deliver(_ rec: MirrorLoanApplicationRatesIDRecord) async throws {
        let request = Acme_Patients_V1_GetMedicalRecordLifecycleRequest.with {
            $0.medicalRecordID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getMedicalRecordLifecycle(request)
        }
    }
}

/// Writes records to acme.prescriptions.v1.RefillCalculationService.
struct MirrorLoanApplicationRatesIDRefillCalculation: MirrorLoanApplicationRatesIDDestination {
    let client: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>

    func deliver(_ rec: MirrorLoanApplicationRatesIDRecord) async throws {
        _ = try await client.getRefillRates(.with {
            $0.refillID = rec.correlationID
        })
    }
}

/// Reads acme.lending.v1.LoanApplicationCalculationService/GetLoanApplicationRates and hands what it keeps to the sink of its kind.
enum MirrorLoanApplicationRatesID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Lending_V1_LoanApplicationCalculationService.Client(wrapping: mesh)
        let got = try await origin.getLoanApplicationRates(.with { $0.loanApplicationID = "primary-mirror-loan-application-rates-id" })
        let entry = MirrorLoanApplicationRatesIDRecord(
            correlationID: got.result.correlationID,
            status: got.result.status
        )
        let sinks: [String: any MirrorLoanApplicationRatesIDDestination] = [
            "compliance-case": MirrorLoanApplicationRatesIDComplianceCase(client: Acme_Compliance_V1_ComplianceCaseService.Client(wrapping: mesh)),
            "medical-record-lifecycle": MirrorLoanApplicationRatesIDMedicalRecordLifecycle(client: Acme_Patients_V1_MedicalRecordLifecycleService.Client(wrapping: mesh)),
            "refill-calculation": MirrorLoanApplicationRatesIDRefillCalculation(client: Acme_Prescriptions_V1_RefillCalculationService.Client(wrapping: mesh)),
        ]
        try await route("compliance-case", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: MirrorLoanApplicationRatesIDRecord, _ sinks: [String: any MirrorLoanApplicationRatesIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
