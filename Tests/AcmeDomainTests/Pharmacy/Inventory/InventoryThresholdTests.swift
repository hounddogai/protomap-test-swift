@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryThresholdTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newInventoryThreshold("code-360", title: "title-235")
        #expect(item.status == Pharmacy.InventoryThresholdStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newInventoryThreshold("code-360", title: "title-235")
        try item.moveTo(Pharmacy.InventoryThresholdStatus.published)
        #expect(item.status == Pharmacy.InventoryThresholdStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newInventoryThreshold("code-360", title: "title-235")
        item.status = Pharmacy.InventoryThresholdStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryThresholdStatus.created) }
    }
}
