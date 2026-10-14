@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictStatementForecastTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newStrictStatementForecast("code-408", title: "title-961")
        #expect(item.status == RevenueCycle.StrictStatementForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newStrictStatementForecast("code-408", title: "title-961")
        try item.moveTo(RevenueCycle.StrictStatementForecastStatus.inProgress)
        #expect(item.status == RevenueCycle.StrictStatementForecastStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newStrictStatementForecast("code-408", title: "title-961")
        item.status = RevenueCycle.StrictStatementForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictStatementForecastStatus.planned) }
    }
}
