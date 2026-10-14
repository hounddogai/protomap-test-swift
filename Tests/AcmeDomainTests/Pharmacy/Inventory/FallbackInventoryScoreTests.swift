@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInventoryScoreTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newFallbackInventoryScore("code-362", name: "name-501")
        #expect(item.status == Pharmacy.FallbackInventoryScoreStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newFallbackInventoryScore("code-362", name: "name-501")
        try item.moveTo(Pharmacy.FallbackInventoryScoreStatus.approved)
        #expect(item.status == Pharmacy.FallbackInventoryScoreStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newFallbackInventoryScore("code-362", name: "name-501")
        item.status = Pharmacy.FallbackInventoryScoreStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackInventoryScoreStatus.proposed) }
    }
}
