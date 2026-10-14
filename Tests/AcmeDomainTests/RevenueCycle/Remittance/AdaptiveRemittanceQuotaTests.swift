@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveRemittanceQuotaTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newAdaptiveRemittanceQuota("code-890", label: "label-588")
        #expect(item.status == RevenueCycle.AdaptiveRemittanceQuotaStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newAdaptiveRemittanceQuota("code-890", label: "label-588")
        try item.moveTo(RevenueCycle.AdaptiveRemittanceQuotaStatus.granted)
        #expect(item.status == RevenueCycle.AdaptiveRemittanceQuotaStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newAdaptiveRemittanceQuota("code-890", label: "label-588")
        item.status = RevenueCycle.AdaptiveRemittanceQuotaStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveRemittanceQuotaStatus.requested) }
    }
}
