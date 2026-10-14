@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInventoryBatchTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newDefaultInventoryBatch("code-877", title: "title-225")
        #expect(item.status == Pharmacy.DefaultInventoryBatchStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newDefaultInventoryBatch("code-877", title: "title-225")
        try item.moveTo(Pharmacy.DefaultInventoryBatchStatus.pending)
        #expect(item.status == Pharmacy.DefaultInventoryBatchStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newDefaultInventoryBatch("code-877", title: "title-225")
        item.status = Pharmacy.DefaultInventoryBatchStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultInventoryBatchStatus.draft) }
    }
}
