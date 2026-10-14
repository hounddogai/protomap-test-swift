@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedClaimForecastTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newCappedClaimForecast("code-720", name: "name-182")
        #expect(item.status == RevenueCycle.CappedClaimForecastStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newCappedClaimForecast("code-720", name: "name-182")
        try item.moveTo(RevenueCycle.CappedClaimForecastStatus.running)
        #expect(item.status == RevenueCycle.CappedClaimForecastStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newCappedClaimForecast("code-720", name: "name-182")
        item.status = RevenueCycle.CappedClaimForecastStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedClaimForecastStatus.new) }
    }
}
