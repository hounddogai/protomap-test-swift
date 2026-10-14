@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictModalitySnapshotTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newStrictModalitySnapshot("code-359", label: "label-371")
        #expect(item.status == Imaging.StrictModalitySnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newStrictModalitySnapshot("code-359", label: "label-371")
        try item.moveTo(Imaging.StrictModalitySnapshotStatus.rejected)
        #expect(item.status == Imaging.StrictModalitySnapshotStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newStrictModalitySnapshot("code-359", label: "label-371")
        item.status = Imaging.StrictModalitySnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictModalitySnapshotStatus.proposed) }
    }
}
