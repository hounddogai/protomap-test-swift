@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureNoticeTests {
    @Test func startsInCreated() throws {
        let item = Consent.newDisclosureNotice("code-788", title: "title-294")
        #expect(item.status == Consent.DisclosureNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newDisclosureNotice("code-788", title: "title-294")
        try item.moveTo(Consent.DisclosureNoticeStatus.validated)
        #expect(item.status == Consent.DisclosureNoticeStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newDisclosureNotice("code-788", title: "title-294")
        item.status = Consent.DisclosureNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureNoticeStatus.created) }
    }
}
