@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationSummaryTests {
    @Test func startsInNew() throws {
        let item = Consent.newCappedRevocationSummary("code-547", label: "label-78")
        #expect(item.status == Consent.CappedRevocationSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newCappedRevocationSummary("code-547", label: "label-78")
        try item.moveTo(Consent.CappedRevocationSummaryStatus.queued)
        #expect(item.status == Consent.CappedRevocationSummaryStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newCappedRevocationSummary("code-547", label: "label-78")
        item.status = Consent.CappedRevocationSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedRevocationSummaryStatus.new) }
    }
}
