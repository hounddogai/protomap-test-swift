@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessSummaryTests {
    @Test func startsInIdle() throws {
        let item = Consent.newWitnessSummary("code-524", label: "label-686")
        #expect(item.status == Consent.WitnessSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newWitnessSummary("code-524", label: "label-686")
        try item.moveTo(Consent.WitnessSummaryStatus.warming)
        #expect(item.status == Consent.WitnessSummaryStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newWitnessSummary("code-524", label: "label-686")
        item.status = Consent.WitnessSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessSummaryStatus.idle) }
    }
}
