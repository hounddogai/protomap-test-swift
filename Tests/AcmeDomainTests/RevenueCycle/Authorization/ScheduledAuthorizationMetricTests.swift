@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledAuthorizationMetricTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newScheduledAuthorizationMetric("code-193", label: "label-465")
        #expect(item.status == RevenueCycle.ScheduledAuthorizationMetricStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newScheduledAuthorizationMetric("code-193", label: "label-465")
        try item.moveTo(RevenueCycle.ScheduledAuthorizationMetricStatus.active)
        #expect(item.status == RevenueCycle.ScheduledAuthorizationMetricStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newScheduledAuthorizationMetric("code-193", label: "label-465")
        item.status = RevenueCycle.ScheduledAuthorizationMetricStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledAuthorizationMetricStatus.draft) }
    }
}
