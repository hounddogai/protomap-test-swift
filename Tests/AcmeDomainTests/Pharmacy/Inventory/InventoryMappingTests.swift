@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryMappingTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newInventoryMapping("code-165", title: "title-429")
        #expect(item.status == Pharmacy.InventoryMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newInventoryMapping("code-165", title: "title-429")
        try item.moveTo(Pharmacy.InventoryMappingStatus.pending)
        #expect(item.status == Pharmacy.InventoryMappingStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newInventoryMapping("code-165", title: "title-429")
        item.status = Pharmacy.InventoryMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryMappingStatus.draft) }
    }
}
