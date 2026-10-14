@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionSummaryTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newInteractionSummary("code-856", title: "title-450")
        #expect(item.status == Pharmacy.InteractionSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newInteractionSummary("code-856", title: "title-450")
        try item.moveTo(Pharmacy.InteractionSummaryStatus.retired)
        #expect(item.status == Pharmacy.InteractionSummaryStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newInteractionSummary("code-856", title: "title-450")
        item.status = Pharmacy.InteractionSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionSummaryStatus.created) }
    }
}
