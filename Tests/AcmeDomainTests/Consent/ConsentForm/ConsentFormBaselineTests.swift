@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormBaselineTests {
    @Test func startsInOpen() throws {
        let item = Consent.newConsentFormBaseline("code-608", name: "name-908")
        #expect(item.status == Consent.ConsentFormBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newConsentFormBaseline("code-608", name: "name-908")
        try item.moveTo(Consent.ConsentFormBaselineStatus.inReview)
        #expect(item.status == Consent.ConsentFormBaselineStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newConsentFormBaseline("code-608", name: "name-908")
        item.status = Consent.ConsentFormBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormBaselineStatus.`open`) }
    }
}
