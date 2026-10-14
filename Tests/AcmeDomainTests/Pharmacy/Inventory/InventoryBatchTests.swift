@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryBatchTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newInventoryBatch("code-657", title: "title-266")
        #expect(item.status == Pharmacy.InventoryBatchStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newInventoryBatch("code-657", title: "title-266")
        try item.moveTo(Pharmacy.InventoryBatchStatus.validated)
        #expect(item.status == Pharmacy.InventoryBatchStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newInventoryBatch("code-657", title: "title-266")
        item.status = Pharmacy.InventoryBatchStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryBatchStatus.created) }
    }
}
