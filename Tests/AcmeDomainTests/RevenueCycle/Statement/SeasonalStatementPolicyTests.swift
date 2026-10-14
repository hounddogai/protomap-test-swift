@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalStatementPolicyTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newSeasonalStatementPolicy("code-741", name: "name-89")
        #expect(item.status == RevenueCycle.SeasonalStatementPolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newSeasonalStatementPolicy("code-741", name: "name-89")
        try item.moveTo(RevenueCycle.SeasonalStatementPolicyStatus.running)
        #expect(item.status == RevenueCycle.SeasonalStatementPolicyStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newSeasonalStatementPolicy("code-741", name: "name-89")
        item.status = RevenueCycle.SeasonalStatementPolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.SeasonalStatementPolicyStatus.new) }
    }
}
