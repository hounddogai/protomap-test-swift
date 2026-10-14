@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalStatementBaselineTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRegionalStatementBaseline("code-544", label: "label-902")
        #expect(item.status == RevenueCycle.RegionalStatementBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newRegionalStatementBaseline("code-544", label: "label-902")
        try item.moveTo(RevenueCycle.RegionalStatementBaselineStatus.running)
        #expect(item.status == RevenueCycle.RegionalStatementBaselineStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRegionalStatementBaseline("code-544", label: "label-902")
        item.status = RevenueCycle.RegionalStatementBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalStatementBaselineStatus.new) }
    }
}
