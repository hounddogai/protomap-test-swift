@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalReadDraftTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newRegionalReadDraft("code-208", title: "title-557")
        #expect(item.status == Imaging.RegionalReadDraftStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newRegionalReadDraft("code-208", title: "title-557")
        try item.moveTo(Imaging.RegionalReadDraftStatus.scheduled)
        #expect(item.status == Imaging.RegionalReadDraftStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newRegionalReadDraft("code-208", title: "title-557")
        item.status = Imaging.RegionalReadDraftStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalReadDraftStatus.planned) }
    }
}
