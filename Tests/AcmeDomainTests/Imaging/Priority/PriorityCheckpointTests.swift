@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newPriorityCheckpoint("code-815", label: "label-98")
        #expect(item.status == Imaging.PriorityCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newPriorityCheckpoint("code-815", label: "label-98")
        try item.moveTo(Imaging.PriorityCheckpointStatus.inProgress)
        #expect(item.status == Imaging.PriorityCheckpointStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newPriorityCheckpoint("code-815", label: "label-98")
        item.status = Imaging.PriorityCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityCheckpointStatus.planned) }
    }
}
