@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedProxySummaryTests {
    @Test func startsInDraft() throws {
        let item = Consent.newWeightedProxySummary("code-103", name: "name-638")
        #expect(item.status == Consent.WeightedProxySummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Consent.newWeightedProxySummary("code-103", name: "name-638")
        try item.moveTo(Consent.WeightedProxySummaryStatus.closed)
        #expect(item.status == Consent.WeightedProxySummaryStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newWeightedProxySummary("code-103", name: "name-638")
        item.status = Consent.WeightedProxySummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WeightedProxySummaryStatus.draft) }
    }
}
