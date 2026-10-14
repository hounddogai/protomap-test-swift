@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledDenialMetricTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newScheduledDenialMetric("code-324", title: "title-381")
        #expect(item.status == RevenueCycle.ScheduledDenialMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newScheduledDenialMetric("code-324", title: "title-381")
        try item.moveTo(RevenueCycle.ScheduledDenialMetricStatus.completed)
        #expect(item.status == RevenueCycle.ScheduledDenialMetricStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newScheduledDenialMetric("code-324", title: "title-381")
        item.status = RevenueCycle.ScheduledDenialMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledDenialMetricStatus.planned) }
    }
}
