@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyMetricTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newRollingStudyMetric("code-779", name: "name-482")
        #expect(item.status == Imaging.RollingStudyMetricStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Imaging.newRollingStudyMetric("code-779", name: "name-482")
        try item.moveTo(Imaging.RollingStudyMetricStatus.retired)
        #expect(item.status == Imaging.RollingStudyMetricStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newRollingStudyMetric("code-779", name: "name-482")
        item.status = Imaging.RollingStudyMetricStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingStudyMetricStatus.created) }
    }
}
