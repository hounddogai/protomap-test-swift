@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceForecastTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newManualRemittanceForecast("code-516", title: "title-357")
        #expect(item.status == RevenueCycle.ManualRemittanceForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newManualRemittanceForecast("code-516", title: "title-357")
        try item.moveTo(RevenueCycle.ManualRemittanceForecastStatus.approved)
        #expect(item.status == RevenueCycle.ManualRemittanceForecastStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newManualRemittanceForecast("code-516", title: "title-357")
        item.status = RevenueCycle.ManualRemittanceForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualRemittanceForecastStatus.proposed) }
    }
}
