@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedStudyBundleTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newWeightedStudyBundle("code-771", label: "label-984")
        #expect(item.status == Imaging.WeightedStudyBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newWeightedStudyBundle("code-771", label: "label-984")
        try item.moveTo(Imaging.WeightedStudyBundleStatus.warming)
        #expect(item.status == Imaging.WeightedStudyBundleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newWeightedStudyBundle("code-771", label: "label-984")
        item.status = Imaging.WeightedStudyBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedStudyBundleStatus.idle) }
    }
}
