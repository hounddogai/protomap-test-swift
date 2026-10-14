@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalStudyEntryTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newGlobalStudyEntry("code-853", label: "label-893")
        #expect(item.status == Imaging.GlobalStudyEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newGlobalStudyEntry("code-853", label: "label-893")
        try item.moveTo(Imaging.GlobalStudyEntryStatus.scheduled)
        #expect(item.status == Imaging.GlobalStudyEntryStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newGlobalStudyEntry("code-853", label: "label-893")
        item.status = Imaging.GlobalStudyEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalStudyEntryStatus.planned) }
    }
}
