@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityEstimateTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newModalityEstimate("code-958", label: "label-664")
        #expect(item.status == Imaging.ModalityEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newModalityEstimate("code-958", label: "label-664")
        try item.moveTo(Imaging.ModalityEstimateStatus.warming)
        #expect(item.status == Imaging.ModalityEstimateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newModalityEstimate("code-958", label: "label-664")
        item.status = Imaging.ModalityEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityEstimateStatus.idle) }
    }
}
