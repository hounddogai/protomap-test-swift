@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistSnapshotTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newWorklistSnapshot("code-641", title: "title-645")
        #expect(item.status == Imaging.WorklistSnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newWorklistSnapshot("code-641", title: "title-645")
        try item.moveTo(Imaging.WorklistSnapshotStatus.validated)
        #expect(item.status == Imaging.WorklistSnapshotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newWorklistSnapshot("code-641", title: "title-645")
        item.status = Imaging.WorklistSnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistSnapshotStatus.created) }
    }
}
