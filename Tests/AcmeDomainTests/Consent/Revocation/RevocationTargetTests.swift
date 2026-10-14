@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationTargetTests {
    @Test func startsInRequested() throws {
        let item = Consent.newRevocationTarget("code-860", title: "title-482")
        #expect(item.status == Consent.RevocationTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newRevocationTarget("code-860", title: "title-482")
        try item.moveTo(Consent.RevocationTargetStatus.revoked)
        #expect(item.status == Consent.RevocationTargetStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newRevocationTarget("code-860", title: "title-482")
        item.status = Consent.RevocationTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationTargetStatus.requested) }
    }
}
