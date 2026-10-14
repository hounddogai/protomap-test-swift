@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispenseOverrideTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newBatchedDispenseOverride("code-785", name: "name-538")
        #expect(item.status == Pharmacy.BatchedDispenseOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newBatchedDispenseOverride("code-785", name: "name-538")
        try item.moveTo(Pharmacy.BatchedDispenseOverrideStatus.active)
        #expect(item.status == Pharmacy.BatchedDispenseOverrideStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newBatchedDispenseOverride("code-785", name: "name-538")
        item.status = Pharmacy.BatchedDispenseOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedDispenseOverrideStatus.draft) }
    }
}
