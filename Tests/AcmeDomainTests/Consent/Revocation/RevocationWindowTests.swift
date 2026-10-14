@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationWindowTests {
    @Test func startsInOpen() throws {
        let item = Consent.newRevocationWindow("code-790", title: "title-997")
        #expect(item.status == Consent.RevocationWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newRevocationWindow("code-790", title: "title-997")
        try item.moveTo(Consent.RevocationWindowStatus.inReview)
        #expect(item.status == Consent.RevocationWindowStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newRevocationWindow("code-790", title: "title-997")
        item.status = Consent.RevocationWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationWindowStatus.`open`) }
    }
}
