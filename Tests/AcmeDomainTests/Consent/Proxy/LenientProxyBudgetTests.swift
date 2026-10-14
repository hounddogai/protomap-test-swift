@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyBudgetTests {
    @Test func startsInNew() throws {
        let item = Consent.newLenientProxyBudget("code-778", label: "label-438")
        #expect(item.status == Consent.LenientProxyBudgetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Consent.newLenientProxyBudget("code-778", label: "label-438")
        try item.moveTo(Consent.LenientProxyBudgetStatus.done)
        #expect(item.status == Consent.LenientProxyBudgetStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newLenientProxyBudget("code-778", label: "label-438")
        item.status = Consent.LenientProxyBudgetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientProxyBudgetStatus.new) }
    }
}
