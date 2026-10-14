@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalChargeMetricTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRegionalChargeMetric("code-777", title: "title-413")
        #expect(item.status == RevenueCycle.RegionalChargeMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newRegionalChargeMetric("code-777", title: "title-413")
        try item.moveTo(RevenueCycle.RegionalChargeMetricStatus.granted)
        #expect(item.status == RevenueCycle.RegionalChargeMetricStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRegionalChargeMetric("code-777", title: "title-413")
        item.status = RevenueCycle.RegionalChargeMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalChargeMetricStatus.requested) }
    }
}
