@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementRollupTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newAdaptiveStatementRollup("code-840", title: "title-383")
        #expect(item.status == RevenueCycle.AdaptiveStatementRollupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newAdaptiveStatementRollup("code-840", title: "title-383")
        try item.moveTo(RevenueCycle.AdaptiveStatementRollupStatus.completed)
        #expect(item.status == RevenueCycle.AdaptiveStatementRollupStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newAdaptiveStatementRollup("code-840", title: "title-383")
        item.status = RevenueCycle.AdaptiveStatementRollupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveStatementRollupStatus.planned) }
    }
}
