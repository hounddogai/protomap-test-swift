@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormAuditTests {
    @Test func startsInOpen() throws {
        let item = Consent.newConsentFormAudit("code-12", name: "name-585")
        #expect(item.status == Consent.ConsentFormAuditStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newConsentFormAudit("code-12", name: "name-585")
        try item.moveTo(Consent.ConsentFormAuditStatus.inReview)
        #expect(item.status == Consent.ConsentFormAuditStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newConsentFormAudit("code-12", name: "name-585")
        item.status = Consent.ConsentFormAuditStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormAuditStatus.`open`) }
    }
}
