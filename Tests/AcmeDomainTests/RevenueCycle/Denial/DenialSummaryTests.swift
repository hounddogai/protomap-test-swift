@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialSummaryTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newDenialSummary("code-745", title: "title-274")
        #expect(item.status == RevenueCycle.DenialSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newDenialSummary("code-745", title: "title-274")
        try item.moveTo(RevenueCycle.DenialSummaryStatus.stopped)
        #expect(item.status == RevenueCycle.DenialSummaryStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newDenialSummary("code-745", title: "title-274")
        item.status = RevenueCycle.DenialSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialSummaryStatus.idle) }
    }
}
