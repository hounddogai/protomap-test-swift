@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalAuthorizationSummaryTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newGlobalAuthorizationSummary("code-169", title: "title-444")
        #expect(item.status == RevenueCycle.GlobalAuthorizationSummaryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newGlobalAuthorizationSummary("code-169", title: "title-444")
        try item.moveTo(RevenueCycle.GlobalAuthorizationSummaryStatus.suspended)
        #expect(item.status == RevenueCycle.GlobalAuthorizationSummaryStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newGlobalAuthorizationSummary("code-169", title: "title-444")
        item.status = RevenueCycle.GlobalAuthorizationSummaryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalAuthorizationSummaryStatus.draft) }
    }
}
