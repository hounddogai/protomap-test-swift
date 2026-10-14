@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingChargeQuotaTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newPendingChargeQuota("code-80", title: "title-637")
        #expect(item.status == RevenueCycle.PendingChargeQuotaStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = RevenueCycle.newPendingChargeQuota("code-80", title: "title-637")
        try item.moveTo(RevenueCycle.PendingChargeQuotaStatus.failed)
        #expect(item.status == RevenueCycle.PendingChargeQuotaStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newPendingChargeQuota("code-80", title: "title-637")
        item.status = RevenueCycle.PendingChargeQuotaStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingChargeQuotaStatus.new) }
    }
}
