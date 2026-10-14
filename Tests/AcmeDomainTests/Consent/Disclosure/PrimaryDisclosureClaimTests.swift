@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryDisclosureClaimTests {
    @Test func startsInCreated() throws {
        let item = Consent.newPrimaryDisclosureClaim("code-270", title: "title-820")
        #expect(item.status == Consent.PrimaryDisclosureClaimStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newPrimaryDisclosureClaim("code-270", title: "title-820")
        try item.moveTo(Consent.PrimaryDisclosureClaimStatus.validated)
        #expect(item.status == Consent.PrimaryDisclosureClaimStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newPrimaryDisclosureClaim("code-270", title: "title-820")
        item.status = Consent.PrimaryDisclosureClaimStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryDisclosureClaimStatus.created) }
    }
}
