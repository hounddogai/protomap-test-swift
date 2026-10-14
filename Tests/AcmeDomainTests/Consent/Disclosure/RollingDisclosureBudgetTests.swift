@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingDisclosureBudgetTests {
    @Test func startsInNew() throws {
        let item = Consent.newRollingDisclosureBudget("code-928", label: "label-645")
        #expect(item.status == Consent.RollingDisclosureBudgetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newRollingDisclosureBudget("code-928", label: "label-645")
        try item.moveTo(Consent.RollingDisclosureBudgetStatus.running)
        #expect(item.status == Consent.RollingDisclosureBudgetStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newRollingDisclosureBudget("code-928", label: "label-645")
        item.status = Consent.RollingDisclosureBudgetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingDisclosureBudgetStatus.new) }
    }
}
