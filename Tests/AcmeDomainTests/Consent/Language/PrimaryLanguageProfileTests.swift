@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryLanguageProfileTests {
    @Test func startsInCreated() throws {
        let item = Consent.newPrimaryLanguageProfile("code-52", title: "title-821")
        #expect(item.status == Consent.PrimaryLanguageProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newPrimaryLanguageProfile("code-52", title: "title-821")
        try item.moveTo(Consent.PrimaryLanguageProfileStatus.published)
        #expect(item.status == Consent.PrimaryLanguageProfileStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newPrimaryLanguageProfile("code-52", title: "title-821")
        item.status = Consent.PrimaryLanguageProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryLanguageProfileStatus.created) }
    }
}
