@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationSummaryTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newAuthorizationSummary("code-247", title: "title-780")
        #expect(item.status == RevenueCycle.AuthorizationSummaryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newAuthorizationSummary("code-247", title: "title-780")
        try item.moveTo(RevenueCycle.AuthorizationSummaryStatus.resolved)
        #expect(item.status == RevenueCycle.AuthorizationSummaryStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newAuthorizationSummary("code-247", title: "title-780")
        item.status = RevenueCycle.AuthorizationSummaryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationSummaryStatus.`open`) }
    }
}
