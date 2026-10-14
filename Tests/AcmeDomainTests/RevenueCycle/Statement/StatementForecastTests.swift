@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementForecastTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newStatementForecast("code-518", title: "title-614")
        #expect(item.status == RevenueCycle.StatementForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newStatementForecast("code-518", title: "title-614")
        try item.moveTo(RevenueCycle.StatementForecastStatus.draining)
        #expect(item.status == RevenueCycle.StatementForecastStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newStatementForecast("code-518", title: "title-614")
        item.status = RevenueCycle.StatementForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementForecastStatus.idle) }
    }
}
