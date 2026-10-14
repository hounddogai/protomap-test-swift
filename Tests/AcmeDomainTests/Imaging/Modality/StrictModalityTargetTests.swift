@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictModalityTargetTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newStrictModalityTarget("code-556", label: "label-991")
        #expect(item.status == Imaging.StrictModalityTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newStrictModalityTarget("code-556", label: "label-991")
        try item.moveTo(Imaging.StrictModalityTargetStatus.draining)
        #expect(item.status == Imaging.StrictModalityTargetStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newStrictModalityTarget("code-556", label: "label-991")
        item.status = Imaging.StrictModalityTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictModalityTargetStatus.idle) }
    }
}
