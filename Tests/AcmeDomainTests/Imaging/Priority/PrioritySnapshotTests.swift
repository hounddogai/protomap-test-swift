@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySnapshotTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newPrioritySnapshot("code-229", label: "label-826")
        #expect(item.status == Imaging.PrioritySnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newPrioritySnapshot("code-229", label: "label-826")
        try item.moveTo(Imaging.PrioritySnapshotStatus.cancelled)
        #expect(item.status == Imaging.PrioritySnapshotStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newPrioritySnapshot("code-229", label: "label-826")
        item.status = Imaging.PrioritySnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrioritySnapshotStatus.planned) }
    }
}
