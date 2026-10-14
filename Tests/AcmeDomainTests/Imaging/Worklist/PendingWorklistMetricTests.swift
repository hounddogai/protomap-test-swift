@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistMetricTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newPendingWorklistMetric("code-367", label: "label-202")
        #expect(item.status == Imaging.PendingWorklistMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newPendingWorklistMetric("code-367", label: "label-202")
        try item.moveTo(Imaging.PendingWorklistMetricStatus.approved)
        #expect(item.status == Imaging.PendingWorklistMetricStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newPendingWorklistMetric("code-367", label: "label-202")
        item.status = Imaging.PendingWorklistMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingWorklistMetricStatus.proposed) }
    }
}
