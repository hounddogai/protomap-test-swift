@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventorySegmentTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newInventorySegment("code-238", name: "name-696")
        #expect(item.status == Pharmacy.InventorySegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newInventorySegment("code-238", name: "name-696")
        try item.moveTo(Pharmacy.InventorySegmentStatus.rejected)
        #expect(item.status == Pharmacy.InventorySegmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newInventorySegment("code-238", name: "name-696")
        item.status = Pharmacy.InventorySegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventorySegmentStatus.proposed) }
    }
}
