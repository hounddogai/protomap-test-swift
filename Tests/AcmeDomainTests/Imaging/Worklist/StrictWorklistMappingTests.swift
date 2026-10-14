@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictWorklistMappingTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newStrictWorklistMapping("code-149", title: "title-327")
        #expect(item.status == Imaging.StrictWorklistMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newStrictWorklistMapping("code-149", title: "title-327")
        try item.moveTo(Imaging.StrictWorklistMappingStatus.pending)
        #expect(item.status == Imaging.StrictWorklistMappingStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newStrictWorklistMapping("code-149", title: "title-327")
        item.status = Imaging.StrictWorklistMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictWorklistMappingStatus.draft) }
    }
}
