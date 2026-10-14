@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientStudyMetricTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newLenientStudyMetric("code-795", label: "label-197")
        #expect(item.status == Imaging.LenientStudyMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newLenientStudyMetric("code-795", label: "label-197")
        try item.moveTo(Imaging.LenientStudyMetricStatus.revoked)
        #expect(item.status == Imaging.LenientStudyMetricStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newLenientStudyMetric("code-795", label: "label-197")
        item.status = Imaging.LenientStudyMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientStudyMetricStatus.requested) }
    }
}
