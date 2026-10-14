@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryReviewTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newInventoryReview("code-473", name: "name-750")
        #expect(item.status == Pharmacy.InventoryReviewStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newInventoryReview("code-473", name: "name-750")
        try item.moveTo(Pharmacy.InventoryReviewStatus.retired)
        #expect(item.status == Pharmacy.InventoryReviewStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newInventoryReview("code-473", name: "name-750")
        item.status = Pharmacy.InventoryReviewStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryReviewStatus.created) }
    }
}
