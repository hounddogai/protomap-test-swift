@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInventoryBundleTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newLegacyInventoryBundle("code-747", label: "label-175")
        #expect(item.status == Pharmacy.LegacyInventoryBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newLegacyInventoryBundle("code-747", label: "label-175")
        try item.moveTo(Pharmacy.LegacyInventoryBundleStatus.approved)
        #expect(item.status == Pharmacy.LegacyInventoryBundleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newLegacyInventoryBundle("code-747", label: "label-175")
        item.status = Pharmacy.LegacyInventoryBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyInventoryBundleStatus.proposed) }
    }
}
