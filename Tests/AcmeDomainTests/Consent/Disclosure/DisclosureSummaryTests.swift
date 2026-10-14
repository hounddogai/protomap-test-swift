@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureSummaryTests {
    @Test func startsInCreated() throws {
        let item = Consent.newDisclosureSummary("code-961", label: "label-148")
        #expect(item.status == Consent.DisclosureSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newDisclosureSummary("code-961", label: "label-148")
        try item.moveTo(Consent.DisclosureSummaryStatus.validated)
        #expect(item.status == Consent.DisclosureSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newDisclosureSummary("code-961", label: "label-148")
        item.status = Consent.DisclosureSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureSummaryStatus.created) }
    }
}
