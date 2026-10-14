import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopySearchIndexEligibilityID keeps of each CheckSearchIndexEligibility response.
struct CopySearchIndexEligibilityIDRecord {
    var referenceID: String
    var message: String
}

/// Where CopySearchIndexEligibilityID hands each record.
protocol CopySearchIndexEligibilityIDSink {
    func deliver(_ rec: CopySearchIndexEligibilityIDRecord) async throws
}

/// Passes records to acme.patients.v1.PatientLifecycleService.
struct CopySearchIndexEligibilityIDPatientLifecycle: CopySearchIndexEligibilityIDSink {
    let client: Acme_Patients_V1_PatientLifecycleService.Client<MeshTransport>

    func deliver(_ rec: CopySearchIndexEligibilityIDRecord) async throws {
        _ = try await client.terminatePatient(.with {
            $0.patientID = rec.message
        })
    }
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleCalculationService.
struct CopySearchIndexEligibilityIDBoxOfficeSaleCalculation: CopySearchIndexEligibilityIDSink {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>

    func deliver(_ rec: CopySearchIndexEligibilityIDRecord) async throws {
        _ = try await client.quoteBoxOfficeSale(.with {
            $0.boxOfficeSale.boxOfficeSaleID = rec.message
            $0.reason = rec.referenceID
        })
    }
}

/// Reads acme.search.v1.SearchIndexValidationService/CheckSearchIndexEligibility and hands what it keeps to the sink of its kind.
enum CopySearchIndexEligibilityID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Search_V1_SearchIndexValidationService.Client(wrapping: mesh)
        let found = try await upstream.checkSearchIndexEligibility(.with { $0.reason = "default-copy-search-index-eligibility-id" })
        let entry = CopySearchIndexEligibilityIDRecord(
            referenceID: found.outcome.referenceID,
            message: found.result.message
        )
        try await act("box-office-sale-calculation", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CopySearchIndexEligibilityIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "patient-lifecycle": { try await CopySearchIndexEligibilityIDPatientLifecycle(client: Acme_Patients_V1_PatientLifecycleService.Client(wrapping: mesh)).deliver(rec) },
            "box-office-sale-calculation": { try await CopySearchIndexEligibilityIDBoxOfficeSaleCalculation(client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(wrapping: mesh)).deliver(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
