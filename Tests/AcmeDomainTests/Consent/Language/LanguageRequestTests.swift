@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageRequestTests {
    @Test func startsInOpen() throws {
        let item = Consent.newLanguageRequest("code-115", title: "title-617")
        #expect(item.status == Consent.LanguageRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newLanguageRequest("code-115", title: "title-617")
        try item.moveTo(Consent.LanguageRequestStatus.resolved)
        #expect(item.status == Consent.LanguageRequestStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newLanguageRequest("code-115", title: "title-617")
        item.status = Consent.LanguageRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageRequestStatus.`open`) }
    }
}
