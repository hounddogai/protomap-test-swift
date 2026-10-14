@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityEntryTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newManualPriorityEntry("code-788", label: "label-234")
        #expect(item.status == Imaging.ManualPriorityEntryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newManualPriorityEntry("code-788", label: "label-234")
        try item.moveTo(Imaging.ManualPriorityEntryStatus.resolved)
        #expect(item.status == Imaging.ManualPriorityEntryStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newManualPriorityEntry("code-788", label: "label-234")
        item.status = Imaging.ManualPriorityEntryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualPriorityEntryStatus.`open`) }
    }
}
