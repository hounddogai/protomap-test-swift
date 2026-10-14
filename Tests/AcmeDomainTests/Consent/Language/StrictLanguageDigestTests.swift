@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictLanguageDigestTests {
    @Test func startsInCreated() throws {
        let item = Consent.newStrictLanguageDigest("code-211", title: "title-888")
        #expect(item.status == Consent.StrictLanguageDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newStrictLanguageDigest("code-211", title: "title-888")
        try item.moveTo(Consent.StrictLanguageDigestStatus.published)
        #expect(item.status == Consent.StrictLanguageDigestStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newStrictLanguageDigest("code-211", title: "title-888")
        item.status = Consent.StrictLanguageDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictLanguageDigestStatus.created) }
    }
}
