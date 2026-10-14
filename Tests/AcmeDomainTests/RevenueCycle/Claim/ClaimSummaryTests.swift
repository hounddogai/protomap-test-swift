@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimSummaryTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newClaimSummary("code-322", label: "label-7")
        #expect(item.status == RevenueCycle.ClaimSummaryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newClaimSummary("code-322", label: "label-7")
        try item.moveTo(RevenueCycle.ClaimSummaryStatus.scheduled)
        #expect(item.status == RevenueCycle.ClaimSummaryStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newClaimSummary("code-322", label: "label-7")
        item.status = RevenueCycle.ClaimSummaryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimSummaryStatus.planned) }
    }
}
