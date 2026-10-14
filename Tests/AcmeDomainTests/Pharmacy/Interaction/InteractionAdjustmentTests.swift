@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAdjustmentTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newInteractionAdjustment("code-971", name: "name-879")
        #expect(item.status == Pharmacy.InteractionAdjustmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newInteractionAdjustment("code-971", name: "name-879")
        try item.moveTo(Pharmacy.InteractionAdjustmentStatus.reopened)
        #expect(item.status == Pharmacy.InteractionAdjustmentStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newInteractionAdjustment("code-971", name: "name-879")
        item.status = Pharmacy.InteractionAdjustmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionAdjustmentStatus.`open`) }
    }
}
