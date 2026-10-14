@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageSummaryTests {
    @Test func startsInDraft() throws {
        let item = Consent.newAdaptiveLanguageSummary("code-677", name: "name-878")
        #expect(item.status == Consent.AdaptiveLanguageSummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newAdaptiveLanguageSummary("code-677", name: "name-878")
        try item.moveTo(Consent.AdaptiveLanguageSummaryStatus.pending)
        #expect(item.status == Consent.AdaptiveLanguageSummaryStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newAdaptiveLanguageSummary("code-677", name: "name-878")
        item.status = Consent.AdaptiveLanguageSummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveLanguageSummaryStatus.draft) }
    }
}
