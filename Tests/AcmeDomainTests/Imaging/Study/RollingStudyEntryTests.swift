@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyEntryTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newRollingStudyEntry("code-604", name: "name-637")
        #expect(item.status == Imaging.RollingStudyEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newRollingStudyEntry("code-604", name: "name-637")
        try item.moveTo(Imaging.RollingStudyEntryStatus.completed)
        #expect(item.status == Imaging.RollingStudyEntryStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newRollingStudyEntry("code-604", name: "name-637")
        item.status = Imaging.RollingStudyEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingStudyEntryStatus.planned) }
    }
}
