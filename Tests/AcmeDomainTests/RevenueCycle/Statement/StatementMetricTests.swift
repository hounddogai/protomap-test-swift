@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementMetricTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newStatementMetric("code-19", name: "name-405")
        #expect(item.status == RevenueCycle.StatementMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newStatementMetric("code-19", name: "name-405")
        try item.moveTo(RevenueCycle.StatementMetricStatus.ready)
        #expect(item.status == RevenueCycle.StatementMetricStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newStatementMetric("code-19", name: "name-405")
        item.status = RevenueCycle.StatementMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementMetricStatus.idle) }
    }
}
