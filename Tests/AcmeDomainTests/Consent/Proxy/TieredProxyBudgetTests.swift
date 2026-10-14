@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredProxyBudgetTests {
    @Test func startsInRequested() throws {
        let item = Consent.newTieredProxyBudget("code-435", label: "label-608")
        #expect(item.status == Consent.TieredProxyBudgetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newTieredProxyBudget("code-435", label: "label-608")
        try item.moveTo(Consent.TieredProxyBudgetStatus.revoked)
        #expect(item.status == Consent.TieredProxyBudgetStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newTieredProxyBudget("code-435", label: "label-608")
        item.status = Consent.TieredProxyBudgetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredProxyBudgetStatus.requested) }
    }
}
