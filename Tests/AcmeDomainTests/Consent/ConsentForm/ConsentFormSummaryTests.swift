@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormSummaryTests {
    @Test func startsInRequested() throws {
        let item = Consent.newConsentFormSummary("code-935", title: "title-57")
        #expect(item.status == Consent.ConsentFormSummaryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newConsentFormSummary("code-935", title: "title-57")
        try item.moveTo(Consent.ConsentFormSummaryStatus.revoked)
        #expect(item.status == Consent.ConsentFormSummaryStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newConsentFormSummary("code-935", title: "title-57")
        item.status = Consent.ConsentFormSummaryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormSummaryStatus.requested) }
    }
}
