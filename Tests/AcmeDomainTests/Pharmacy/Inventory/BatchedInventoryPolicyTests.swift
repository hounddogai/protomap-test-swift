@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInventoryPolicyTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newBatchedInventoryPolicy("code-31", name: "name-258")
        #expect(item.status == Pharmacy.BatchedInventoryPolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newBatchedInventoryPolicy("code-31", name: "name-258")
        try item.moveTo(Pharmacy.BatchedInventoryPolicyStatus.queued)
        #expect(item.status == Pharmacy.BatchedInventoryPolicyStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newBatchedInventoryPolicy("code-31", name: "name-258")
        item.status = Pharmacy.BatchedInventoryPolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedInventoryPolicyStatus.new) }
    }
}
