@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationClaimTests {
    @Test func startsInOpen() throws {
        let item = Consent.newRevocationClaim("code-404", title: "title-640")
        #expect(item.status == Consent.RevocationClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newRevocationClaim("code-404", title: "title-640")
        try item.moveTo(Consent.RevocationClaimStatus.resolved)
        #expect(item.status == Consent.RevocationClaimStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newRevocationClaim("code-404", title: "title-640")
        item.status = Consent.RevocationClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationClaimStatus.`open`) }
    }
}
