@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionBaselineTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newInteractionBaseline("code-666", label: "label-187")
        #expect(item.status == Pharmacy.InteractionBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newInteractionBaseline("code-666", label: "label-187")
        try item.moveTo(Pharmacy.InteractionBaselineStatus.pending)
        #expect(item.status == Pharmacy.InteractionBaselineStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newInteractionBaseline("code-666", label: "label-187")
        item.status = Pharmacy.InteractionBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionBaselineStatus.draft) }
    }
}
