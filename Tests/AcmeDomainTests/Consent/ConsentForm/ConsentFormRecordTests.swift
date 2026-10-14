@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormRecordTests {
    @Test func startsInRequested() throws {
        let item = Consent.newConsentFormRecord("code-821", label: "label-682")
        #expect(item.status == Consent.ConsentFormRecordStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newConsentFormRecord("code-821", label: "label-682")
        try item.moveTo(Consent.ConsentFormRecordStatus.revoked)
        #expect(item.status == Consent.ConsentFormRecordStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newConsentFormRecord("code-821", label: "label-682")
        item.status = Consent.ConsentFormRecordStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormRecordStatus.requested) }
    }
}
