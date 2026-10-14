@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistMetricTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newWorklistMetric("code-155", name: "name-882")
        #expect(item.status == Imaging.WorklistMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newWorklistMetric("code-155", name: "name-882")
        try item.moveTo(Imaging.WorklistMetricStatus.scheduled)
        #expect(item.status == Imaging.WorklistMetricStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newWorklistMetric("code-155", name: "name-882")
        item.status = Imaging.WorklistMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistMetricStatus.planned) }
    }
}
