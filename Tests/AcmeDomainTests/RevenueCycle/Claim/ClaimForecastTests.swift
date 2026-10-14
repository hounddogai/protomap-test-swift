@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimForecastTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newClaimForecast("code-939", label: "label-576")
        #expect(item.status == RevenueCycle.ClaimForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newClaimForecast("code-939", label: "label-576")
        try item.moveTo(RevenueCycle.ClaimForecastStatus.published)
        #expect(item.status == RevenueCycle.ClaimForecastStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newClaimForecast("code-939", label: "label-576")
        item.status = RevenueCycle.ClaimForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimForecastStatus.created) }
    }
}
