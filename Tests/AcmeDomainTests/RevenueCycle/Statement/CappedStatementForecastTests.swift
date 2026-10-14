@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementForecastTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newCappedStatementForecast("code-600", name: "name-363")
        #expect(item.status == RevenueCycle.CappedStatementForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newCappedStatementForecast("code-600", name: "name-363")
        try item.moveTo(RevenueCycle.CappedStatementForecastStatus.stopped)
        #expect(item.status == RevenueCycle.CappedStatementForecastStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newCappedStatementForecast("code-600", name: "name-363")
        item.status = RevenueCycle.CappedStatementForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedStatementForecastStatus.idle) }
    }
}
