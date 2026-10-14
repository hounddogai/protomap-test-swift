@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionMilestoneTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newInteractionMilestone("code-742", name: "name-749")
        #expect(item.status == Pharmacy.InteractionMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newInteractionMilestone("code-742", name: "name-749")
        try item.moveTo(Pharmacy.InteractionMilestoneStatus.active)
        #expect(item.status == Pharmacy.InteractionMilestoneStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newInteractionMilestone("code-742", name: "name-749")
        item.status = Pharmacy.InteractionMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionMilestoneStatus.draft) }
    }
}
