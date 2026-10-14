@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeQuotaTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newTieredChargeQuota("code-407", label: "label-415")
        #expect(item.status == RevenueCycle.TieredChargeQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newTieredChargeQuota("code-407", label: "label-415")
        try item.moveTo(RevenueCycle.TieredChargeQuotaStatus.retired)
        #expect(item.status == RevenueCycle.TieredChargeQuotaStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newTieredChargeQuota("code-407", label: "label-415")
        item.status = RevenueCycle.TieredChargeQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredChargeQuotaStatus.created) }
    }
}
