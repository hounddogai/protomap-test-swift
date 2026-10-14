@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveWorklistNoticeTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newAdaptiveWorklistNotice("code-526", title: "title-912")
        #expect(item.status == Imaging.AdaptiveWorklistNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newAdaptiveWorklistNotice("code-526", title: "title-912")
        try item.moveTo(Imaging.AdaptiveWorklistNoticeStatus.published)
        #expect(item.status == Imaging.AdaptiveWorklistNoticeStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newAdaptiveWorklistNotice("code-526", title: "title-912")
        item.status = Imaging.AdaptiveWorklistNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveWorklistNoticeStatus.created) }
    }
}
