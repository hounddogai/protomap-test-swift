@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryAuthorizationMetricTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newPrimaryAuthorizationMetric("code-976", label: "label-95")
        #expect(item.status == RevenueCycle.PrimaryAuthorizationMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newPrimaryAuthorizationMetric("code-976", label: "label-95")
        try item.moveTo(RevenueCycle.PrimaryAuthorizationMetricStatus.stopped)
        #expect(item.status == RevenueCycle.PrimaryAuthorizationMetricStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newPrimaryAuthorizationMetric("code-976", label: "label-95")
        item.status = RevenueCycle.PrimaryAuthorizationMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PrimaryAuthorizationMetricStatus.idle) }
    }
}
