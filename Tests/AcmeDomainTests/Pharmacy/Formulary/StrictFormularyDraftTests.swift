@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictFormularyDraftTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newStrictFormularyDraft("code-636", title: "title-370")
        #expect(item.status == Pharmacy.StrictFormularyDraftStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newStrictFormularyDraft("code-636", title: "title-370")
        try item.moveTo(Pharmacy.StrictFormularyDraftStatus.suspended)
        #expect(item.status == Pharmacy.StrictFormularyDraftStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newStrictFormularyDraft("code-636", title: "title-370")
        item.status = Pharmacy.StrictFormularyDraftStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictFormularyDraftStatus.draft) }
    }
}
