@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudySnapshotTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newRegionalStudySnapshot("code-193", name: "name-938")
        #expect(item.status == Imaging.RegionalStudySnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newRegionalStudySnapshot("code-193", name: "name-938")
        try item.moveTo(Imaging.RegionalStudySnapshotStatus.scheduled)
        #expect(item.status == Imaging.RegionalStudySnapshotStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newRegionalStudySnapshot("code-193", name: "name-938")
        item.status = Imaging.RegionalStudySnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalStudySnapshotStatus.planned) }
    }
}
