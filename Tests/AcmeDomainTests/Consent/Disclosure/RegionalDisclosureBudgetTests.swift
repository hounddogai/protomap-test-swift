@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalDisclosureBudgetTests {
    @Test func startsInNew() throws {
        let item = Consent.newRegionalDisclosureBudget("code-777", title: "title-954")
        #expect(item.status == Consent.RegionalDisclosureBudgetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newRegionalDisclosureBudget("code-777", title: "title-954")
        try item.moveTo(Consent.RegionalDisclosureBudgetStatus.running)
        #expect(item.status == Consent.RegionalDisclosureBudgetStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newRegionalDisclosureBudget("code-777", title: "title-954")
        item.status = Consent.RegionalDisclosureBudgetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalDisclosureBudgetStatus.new) }
    }
}
