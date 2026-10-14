@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalStudyNoticeTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newGlobalStudyNotice("code-301", name: "name-118")
        #expect(item.status == Imaging.GlobalStudyNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newGlobalStudyNotice("code-301", name: "name-118")
        try item.moveTo(Imaging.GlobalStudyNoticeStatus.validated)
        #expect(item.status == Imaging.GlobalStudyNoticeStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newGlobalStudyNotice("code-301", name: "name-118")
        item.status = Imaging.GlobalStudyNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalStudyNoticeStatus.created) }
    }
}
