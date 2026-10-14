@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredWorklistEntryTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newTieredWorklistEntry("code-849", title: "title-70")
        #expect(item.status == Imaging.TieredWorklistEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newTieredWorklistEntry("code-849", title: "title-70")
        try item.moveTo(Imaging.TieredWorklistEntryStatus.suspended)
        #expect(item.status == Imaging.TieredWorklistEntryStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newTieredWorklistEntry("code-849", title: "title-70")
        item.status = Imaging.TieredWorklistEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredWorklistEntryStatus.draft) }
    }
}
