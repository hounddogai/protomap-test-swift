@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelMetricTests {
    @Test func startsInProposed() throws {
        let item = Labs.newScheduledPanelMetric("code-889", label: "label-548")
        #expect(item.status == Labs.ScheduledPanelMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newScheduledPanelMetric("code-889", label: "label-548")
        try item.moveTo(Labs.ScheduledPanelMetricStatus.approved)
        #expect(item.status == Labs.ScheduledPanelMetricStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newScheduledPanelMetric("code-889", label: "label-548")
        item.status = Labs.ScheduledPanelMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledPanelMetricStatus.proposed) }
    }
}
