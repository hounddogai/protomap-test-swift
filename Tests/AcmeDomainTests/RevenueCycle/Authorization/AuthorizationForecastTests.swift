@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationForecastTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newAuthorizationForecast("code-668", name: "name-405")
        #expect(item.status == RevenueCycle.AuthorizationForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newAuthorizationForecast("code-668", name: "name-405")
        try item.moveTo(RevenueCycle.AuthorizationForecastStatus.approved)
        #expect(item.status == RevenueCycle.AuthorizationForecastStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newAuthorizationForecast("code-668", name: "name-405")
        item.status = RevenueCycle.AuthorizationForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationForecastStatus.proposed) }
    }
}
