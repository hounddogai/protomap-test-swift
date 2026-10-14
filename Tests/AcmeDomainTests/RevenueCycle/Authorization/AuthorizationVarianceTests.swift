@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationVarianceTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newAuthorizationVariance("code-557", title: "title-427")
        #expect(item.status == RevenueCycle.AuthorizationVarianceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newAuthorizationVariance("code-557", title: "title-427")
        try item.moveTo(RevenueCycle.AuthorizationVarianceStatus.suspended)
        #expect(item.status == RevenueCycle.AuthorizationVarianceStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newAuthorizationVariance("code-557", title: "title-427")
        item.status = RevenueCycle.AuthorizationVarianceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationVarianceStatus.draft) }
    }
}
