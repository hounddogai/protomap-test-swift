@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationTierTests {
    @Test func startsInOpen() throws {
        let item = Consent.newRevocationTier("code-809", title: "title-52")
        #expect(item.status == Consent.RevocationTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newRevocationTier("code-809", title: "title-52")
        try item.moveTo(Consent.RevocationTierStatus.inReview)
        #expect(item.status == Consent.RevocationTierStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newRevocationTier("code-809", title: "title-52")
        item.status = Consent.RevocationTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationTierStatus.`open`) }
    }
}
