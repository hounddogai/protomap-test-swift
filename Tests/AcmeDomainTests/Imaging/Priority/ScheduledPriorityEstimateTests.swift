@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityEstimateTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newScheduledPriorityEstimate("code-19", title: "title-625")
        #expect(item.status == Imaging.ScheduledPriorityEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newScheduledPriorityEstimate("code-19", title: "title-625")
        try item.moveTo(Imaging.ScheduledPriorityEstimateStatus.inProgress)
        #expect(item.status == Imaging.ScheduledPriorityEstimateStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newScheduledPriorityEstimate("code-19", title: "title-625")
        item.status = Imaging.ScheduledPriorityEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledPriorityEstimateStatus.planned) }
    }
}
