@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeQuotaTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newChargeQuota("code-771", title: "title-55")
        #expect(item.status == RevenueCycle.ChargeQuotaStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newChargeQuota("code-771", title: "title-55")
        try item.moveTo(RevenueCycle.ChargeQuotaStatus.scheduled)
        #expect(item.status == RevenueCycle.ChargeQuotaStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newChargeQuota("code-771", title: "title-55")
        item.status = RevenueCycle.ChargeQuotaStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeQuotaStatus.planned) }
    }
}
