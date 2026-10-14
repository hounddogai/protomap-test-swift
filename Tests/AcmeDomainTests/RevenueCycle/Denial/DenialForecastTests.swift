@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialForecastTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newDenialForecast("code-819", name: "name-413")
        #expect(item.status == RevenueCycle.DenialForecastStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newDenialForecast("code-819", name: "name-413")
        try item.moveTo(RevenueCycle.DenialForecastStatus.pending)
        #expect(item.status == RevenueCycle.DenialForecastStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newDenialForecast("code-819", name: "name-413")
        item.status = RevenueCycle.DenialForecastStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialForecastStatus.draft) }
    }
}
