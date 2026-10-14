@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationScoreTests {
    @Test func startsInRequested() throws {
        let item = Consent.newRevocationScore("code-345", label: "label-42")
        #expect(item.status == Consent.RevocationScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newRevocationScore("code-345", label: "label-42")
        try item.moveTo(Consent.RevocationScoreStatus.expired)
        #expect(item.status == Consent.RevocationScoreStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newRevocationScore("code-345", label: "label-42")
        item.status = Consent.RevocationScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationScoreStatus.requested) }
    }
}
