@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyDraftTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newAdaptiveFormularyDraft("code-205", title: "title-832")
        #expect(item.status == Pharmacy.AdaptiveFormularyDraftStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newAdaptiveFormularyDraft("code-205", title: "title-832")
        try item.moveTo(Pharmacy.AdaptiveFormularyDraftStatus.inProgress)
        #expect(item.status == Pharmacy.AdaptiveFormularyDraftStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newAdaptiveFormularyDraft("code-205", title: "title-832")
        item.status = Pharmacy.AdaptiveFormularyDraftStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveFormularyDraftStatus.planned) }
    }
}
