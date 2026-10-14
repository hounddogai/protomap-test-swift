@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityNoticeTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newPriorityNotice("code-992", title: "title-486")
        #expect(item.status == Imaging.PriorityNoticeStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newPriorityNotice("code-992", title: "title-486")
        try item.moveTo(Imaging.PriorityNoticeStatus.warming)
        #expect(item.status == Imaging.PriorityNoticeStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newPriorityNotice("code-992", title: "title-486")
        item.status = Imaging.PriorityNoticeStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityNoticeStatus.idle) }
    }
}
