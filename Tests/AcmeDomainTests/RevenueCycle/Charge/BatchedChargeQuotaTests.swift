@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedChargeQuotaTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newBatchedChargeQuota("code-302", title: "title-308")
        #expect(item.status == RevenueCycle.BatchedChargeQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newBatchedChargeQuota("code-302", title: "title-308")
        try item.moveTo(RevenueCycle.BatchedChargeQuotaStatus.retired)
        #expect(item.status == RevenueCycle.BatchedChargeQuotaStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newBatchedChargeQuota("code-302", title: "title-308")
        item.status = RevenueCycle.BatchedChargeQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedChargeQuotaStatus.created) }
    }
}
