@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackClaimForecastTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newFallbackClaimForecast("code-972", name: "name-840")
        #expect(item.status == RevenueCycle.FallbackClaimForecastStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newFallbackClaimForecast("code-972", name: "name-840")
        try item.moveTo(RevenueCycle.FallbackClaimForecastStatus.reopened)
        #expect(item.status == RevenueCycle.FallbackClaimForecastStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newFallbackClaimForecast("code-972", name: "name-840")
        item.status = RevenueCycle.FallbackClaimForecastStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackClaimForecastStatus.`open`) }
    }
}
