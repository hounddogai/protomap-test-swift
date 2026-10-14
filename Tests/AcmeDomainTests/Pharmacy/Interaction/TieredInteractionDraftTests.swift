@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredInteractionDraftTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newTieredInteractionDraft("code-883", title: "title-797")
        #expect(item.status == Pharmacy.TieredInteractionDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newTieredInteractionDraft("code-883", title: "title-797")
        try item.moveTo(Pharmacy.TieredInteractionDraftStatus.validated)
        #expect(item.status == Pharmacy.TieredInteractionDraftStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newTieredInteractionDraft("code-883", title: "title-797")
        item.status = Pharmacy.TieredInteractionDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.TieredInteractionDraftStatus.created) }
    }
}
