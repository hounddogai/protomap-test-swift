@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimSummaryTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newAdaptiveClaimSummary("code-971", title: "title-630")
        #expect(item.status == RevenueCycle.AdaptiveClaimSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newAdaptiveClaimSummary("code-971", title: "title-630")
        try item.moveTo(RevenueCycle.AdaptiveClaimSummaryStatus.validated)
        #expect(item.status == RevenueCycle.AdaptiveClaimSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newAdaptiveClaimSummary("code-971", title: "title-630")
        item.status = RevenueCycle.AdaptiveClaimSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveClaimSummaryStatus.created) }
    }
}
