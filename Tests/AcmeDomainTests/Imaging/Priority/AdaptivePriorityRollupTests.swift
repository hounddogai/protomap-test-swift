@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityRollupTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newAdaptivePriorityRollup("code-761", label: "label-817")
        #expect(item.status == Imaging.AdaptivePriorityRollupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newAdaptivePriorityRollup("code-761", label: "label-817")
        try item.moveTo(Imaging.AdaptivePriorityRollupStatus.inProgress)
        #expect(item.status == Imaging.AdaptivePriorityRollupStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newAdaptivePriorityRollup("code-761", label: "label-817")
        item.status = Imaging.AdaptivePriorityRollupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptivePriorityRollupStatus.planned) }
    }
}
