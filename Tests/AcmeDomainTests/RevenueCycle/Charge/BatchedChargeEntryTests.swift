@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedChargeEntryTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newBatchedChargeEntry("code-952", label: "label-158")
        #expect(item.status == RevenueCycle.BatchedChargeEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newBatchedChargeEntry("code-952", label: "label-158")
        try item.moveTo(RevenueCycle.BatchedChargeEntryStatus.suspended)
        #expect(item.status == RevenueCycle.BatchedChargeEntryStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newBatchedChargeEntry("code-952", label: "label-158")
        item.status = RevenueCycle.BatchedChargeEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedChargeEntryStatus.draft) }
    }
}
