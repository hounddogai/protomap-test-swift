@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationSummaryTests {
    @Test func startsInIdle() throws {
        let item = Consent.newFallbackRevocationSummary("code-344", label: "label-522")
        #expect(item.status == Consent.FallbackRevocationSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Consent.newFallbackRevocationSummary("code-344", label: "label-522")
        try item.moveTo(Consent.FallbackRevocationSummaryStatus.stopped)
        #expect(item.status == Consent.FallbackRevocationSummaryStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newFallbackRevocationSummary("code-344", label: "label-522")
        item.status = Consent.FallbackRevocationSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackRevocationSummaryStatus.idle) }
    }
}
