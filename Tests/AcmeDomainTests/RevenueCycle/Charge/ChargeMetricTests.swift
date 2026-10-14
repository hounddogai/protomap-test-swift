@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeMetricTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newChargeMetric("code-464", title: "title-919")
        #expect(item.status == RevenueCycle.ChargeMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newChargeMetric("code-464", title: "title-919")
        try item.moveTo(RevenueCycle.ChargeMetricStatus.approved)
        #expect(item.status == RevenueCycle.ChargeMetricStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newChargeMetric("code-464", title: "title-919")
        item.status = RevenueCycle.ChargeMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeMetricStatus.proposed) }
    }
}
