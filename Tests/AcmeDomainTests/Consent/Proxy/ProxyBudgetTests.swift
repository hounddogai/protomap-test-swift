@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyBudgetTests {
    @Test func startsInIdle() throws {
        let item = Consent.newProxyBudget("code-336", name: "name-523")
        #expect(item.status == Consent.ProxyBudgetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newProxyBudget("code-336", name: "name-523")
        try item.moveTo(Consent.ProxyBudgetStatus.warming)
        #expect(item.status == Consent.ProxyBudgetStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newProxyBudget("code-336", name: "name-523")
        item.status = Consent.ProxyBudgetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyBudgetStatus.idle) }
    }
}
