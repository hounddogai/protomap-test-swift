@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistNoticeTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newPrimaryWorklistNotice("code-765", label: "label-345")
        #expect(item.status == Imaging.PrimaryWorklistNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newPrimaryWorklistNotice("code-765", label: "label-345")
        try item.moveTo(Imaging.PrimaryWorklistNoticeStatus.published)
        #expect(item.status == Imaging.PrimaryWorklistNoticeStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newPrimaryWorklistNotice("code-765", label: "label-345")
        item.status = Imaging.PrimaryWorklistNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryWorklistNoticeStatus.created) }
    }
}
