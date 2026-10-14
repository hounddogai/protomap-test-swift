@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryScoreTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newInventoryScore("code-123", title: "title-803")
        #expect(item.status == Pharmacy.InventoryScoreStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newInventoryScore("code-123", title: "title-803")
        try item.moveTo(Pharmacy.InventoryScoreStatus.approved)
        #expect(item.status == Pharmacy.InventoryScoreStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newInventoryScore("code-123", title: "title-803")
        item.status = Pharmacy.InventoryScoreStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryScoreStatus.proposed) }
    }
}
