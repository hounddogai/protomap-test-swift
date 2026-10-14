@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormScoreTests {
    @Test func startsInRequested() throws {
        let item = Consent.newConsentFormScore("code-867", name: "name-734")
        #expect(item.status == Consent.ConsentFormScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newConsentFormScore("code-867", name: "name-734")
        try item.moveTo(Consent.ConsentFormScoreStatus.expired)
        #expect(item.status == Consent.ConsentFormScoreStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newConsentFormScore("code-867", name: "name-734")
        item.status = Consent.ConsentFormScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormScoreStatus.requested) }
    }
}
