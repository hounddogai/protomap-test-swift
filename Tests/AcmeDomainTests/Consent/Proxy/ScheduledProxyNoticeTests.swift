@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyNoticeTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newScheduledProxyNotice("code-744", title: "title-159")
        #expect(item.status == Consent.ScheduledProxyNoticeStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newScheduledProxyNotice("code-744", title: "title-159")
        try item.moveTo(Consent.ScheduledProxyNoticeStatus.inProgress)
        #expect(item.status == Consent.ScheduledProxyNoticeStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newScheduledProxyNotice("code-744", title: "title-159")
        item.status = Consent.ScheduledProxyNoticeStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledProxyNoticeStatus.planned) }
    }
}
