@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormMappingTests {
    @Test func startsInProposed() throws {
        let item = Consent.newConsentFormMapping("code-972", label: "label-60")
        #expect(item.status == Consent.ConsentFormMappingStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newConsentFormMapping("code-972", label: "label-60")
        try item.moveTo(Consent.ConsentFormMappingStatus.approved)
        #expect(item.status == Consent.ConsentFormMappingStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newConsentFormMapping("code-972", label: "label-60")
        item.status = Consent.ConsentFormMappingStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormMappingStatus.proposed) }
    }
}
