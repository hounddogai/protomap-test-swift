@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageSummaryTests {
    @Test func startsInCreated() throws {
        let item = Consent.newLanguageSummary("code-649", title: "title-616")
        #expect(item.status == Consent.LanguageSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newLanguageSummary("code-649", title: "title-616")
        try item.moveTo(Consent.LanguageSummaryStatus.validated)
        #expect(item.status == Consent.LanguageSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newLanguageSummary("code-649", title: "title-616")
        item.status = Consent.LanguageSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageSummaryStatus.created) }
    }
}
