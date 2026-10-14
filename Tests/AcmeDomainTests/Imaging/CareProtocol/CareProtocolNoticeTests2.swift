@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolNoticeTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newCareProtocolNotice("code-576", title: "title-512")
        #expect(item.status == Imaging.CareProtocolNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newCareProtocolNotice("code-576", title: "title-512")
        try item.moveTo(Imaging.CareProtocolNoticeStatus.revoked)
        #expect(item.status == Imaging.CareProtocolNoticeStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newCareProtocolNotice("code-576", title: "title-512")
        item.status = Imaging.CareProtocolNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolNoticeStatus.requested) }
    }
}
