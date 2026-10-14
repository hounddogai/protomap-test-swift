@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityTargetTests {
    @Test func startsInNew() throws {
        let item = Imaging.newManualPriorityTarget("code-296", label: "label-372")
        #expect(item.status == Imaging.ManualPriorityTargetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newManualPriorityTarget("code-296", label: "label-372")
        try item.moveTo(Imaging.ManualPriorityTargetStatus.running)
        #expect(item.status == Imaging.ManualPriorityTargetStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newManualPriorityTarget("code-296", label: "label-372")
        item.status = Imaging.ManualPriorityTargetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualPriorityTargetStatus.new) }
    }
}
