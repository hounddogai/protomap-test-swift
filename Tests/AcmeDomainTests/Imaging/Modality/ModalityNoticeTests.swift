@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityNoticeTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newModalityNotice("code-955", label: "label-698")
        #expect(item.status == Imaging.ModalityNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newModalityNotice("code-955", label: "label-698")
        try item.moveTo(Imaging.ModalityNoticeStatus.published)
        #expect(item.status == Imaging.ModalityNoticeStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newModalityNotice("code-955", label: "label-698")
        item.status = Imaging.ModalityNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityNoticeStatus.created) }
    }
}
