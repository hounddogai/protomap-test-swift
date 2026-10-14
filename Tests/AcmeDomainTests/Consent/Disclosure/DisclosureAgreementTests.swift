@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAgreementTests {
    @Test func startsInIdle() throws {
        let item = Consent.newDisclosureAgreement("code-825", title: "title-129")
        #expect(item.status == Consent.DisclosureAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Consent.newDisclosureAgreement("code-825", title: "title-129")
        try item.moveTo(Consent.DisclosureAgreementStatus.draining)
        #expect(item.status == Consent.DisclosureAgreementStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newDisclosureAgreement("code-825", title: "title-129")
        item.status = Consent.DisclosureAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureAgreementStatus.idle) }
    }
}
