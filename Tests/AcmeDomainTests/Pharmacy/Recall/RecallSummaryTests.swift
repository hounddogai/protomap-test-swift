@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallSummaryTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newRecallSummary("code-918", title: "title-617")
        #expect(item.status == Pharmacy.RecallSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newRecallSummary("code-918", title: "title-617")
        try item.moveTo(Pharmacy.RecallSummaryStatus.published)
        #expect(item.status == Pharmacy.RecallSummaryStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newRecallSummary("code-918", title: "title-617")
        item.status = Pharmacy.RecallSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallSummaryStatus.created) }
    }
}
