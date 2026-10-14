@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormRequestTests {
    @Test func startsInProposed() throws {
        let item = Consent.newConsentFormRequest("code-570", label: "label-876")
        #expect(item.status == Consent.ConsentFormRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newConsentFormRequest("code-570", label: "label-876")
        try item.moveTo(Consent.ConsentFormRequestStatus.rejected)
        #expect(item.status == Consent.ConsentFormRequestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newConsentFormRequest("code-570", label: "label-876")
        item.status = Consent.ConsentFormRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormRequestStatus.proposed) }
    }
}
