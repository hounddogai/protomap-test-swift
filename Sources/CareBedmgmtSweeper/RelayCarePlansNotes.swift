import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayCarePlansNotes keeps of each RecalculateCarePlans response.
struct RelayCarePlansNotesRecord {
    var notes: String
    var carePlanID: String
    var message: String
    var number: String
}

/// Where RelayCarePlansNotes hands each record.
protocol RelayCarePlansNotesDestination {
    func forward(_ rec: RelayCarePlansNotesRecord) async throws
}

/// Writes records to acme.patients.v1.AllergyValidationService.
struct RelayCarePlansNotesAllergyValidation: RelayCarePlansNotesDestination {
    let client: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>

    func forward(_ rec: RelayCarePlansNotesRecord) async throws {
        _ = try await client.getAllergyRules(.with {
            $0.allergyID = rec.notes
        })
    }
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleCalculationService.
struct RelayCarePlansNotesBoxOfficeSaleCalculation: RelayCarePlansNotesDestination {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>

    func forward(_ rec: RelayCarePlansNotesRecord) async throws {
        let request = Acme_Boxoffice_V1_CalculateBoxOfficeSaleRequest.with {
            $0.details.currencyCode = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.calculateBoxOfficeSale(request)
        }
    }
}

/// Writes records to acme.admissions.v1.AdmissionQueryService.
struct RelayCarePlansNotesAdmissionQuery: RelayCarePlansNotesDestination {
    let client: Acme_Admissions_V1_AdmissionQueryService.Client<MeshTransport>

    func forward(_ rec: RelayCarePlansNotesRecord) async throws {
        let request = Acme_Admissions_V1_BrowseAdmissionsRequest.with {
            $0.page.pageToken = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browseAdmissions(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct RelayCarePlansNotesLogOnly: RelayCarePlansNotesDestination {
    let logger = Logger(label: "acme.relay-care-plans-notes")

    func forward(_ rec: RelayCarePlansNotesRecord) async throws {
        logger.info("No sink for record", metadata: ["notes": .string(rec.notes)])
    }
}

/// Reads acme.careplans.v1.CarePlanCalculationService/RecalculateCarePlans and hands what it keeps to the sink of its kind.
enum RelayCarePlansNotes {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh)
        let response = try await source.recalculateCarePlans(.with { $0.reason = "default-relay-care-plans-notes" })
        let row = RelayCarePlansNotesRecord(
            notes: response.carePlan.notes,
            carePlanID: response.carePlan.carePlanID,
            message: Kit.Text.normalize(response.result.message),
            number: response.carePlan.number
        )
        try await dispatch("box-office-sale-calculation", row, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: RelayCarePlansNotesRecord, _ mesh: MeshClient) async throws {
        var write: (RelayCarePlansNotesRecord) async throws -> Void = RelayCarePlansNotesLogOnly().forward
        switch kind {
        case "allergy-validation":
            write = RelayCarePlansNotesAllergyValidation(client: Acme_Patients_V1_AllergyValidationService.Client(wrapping: mesh)).forward
        case "box-office-sale-calculation":
            write = RelayCarePlansNotesBoxOfficeSaleCalculation(client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(wrapping: mesh)).forward
        case "admission-query":
            write = RelayCarePlansNotesAdmissionQuery(client: Acme_Admissions_V1_AdmissionQueryService.Client(wrapping: mesh)).forward
        default:
            break
        }
        try await write(rec)
    }
}
