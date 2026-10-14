@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryGroupTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newInventoryGroup("code-387", label: "label-389")
        #expect(item.status == Pharmacy.InventoryGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newInventoryGroup("code-387", label: "label-389")
        try item.moveTo(Pharmacy.InventoryGroupStatus.pending)
        #expect(item.status == Pharmacy.InventoryGroupStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newInventoryGroup("code-387", label: "label-389")
        item.status = Pharmacy.InventoryGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryGroupStatus.draft) }
    }
}
