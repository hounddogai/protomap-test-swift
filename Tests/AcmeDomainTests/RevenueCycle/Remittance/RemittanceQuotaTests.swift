@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceQuotaTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newRemittanceQuota("code-292", name: "name-26")
        #expect(item.status == RevenueCycle.RemittanceQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newRemittanceQuota("code-292", name: "name-26")
        try item.moveTo(RevenueCycle.RemittanceQuotaStatus.validated)
        #expect(item.status == RevenueCycle.RemittanceQuotaStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newRemittanceQuota("code-292", name: "name-26")
        item.status = RevenueCycle.RemittanceQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceQuotaStatus.created) }
    }
}
