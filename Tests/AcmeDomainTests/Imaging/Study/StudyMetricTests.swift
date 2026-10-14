@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyMetricTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newStudyMetric("code-324", label: "label-952")
        #expect(item.status == Imaging.StudyMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newStudyMetric("code-324", label: "label-952")
        try item.moveTo(Imaging.StudyMetricStatus.approved)
        #expect(item.status == Imaging.StudyMetricStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newStudyMetric("code-324", label: "label-952")
        item.status = Imaging.StudyMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyMetricStatus.proposed) }
    }
}
