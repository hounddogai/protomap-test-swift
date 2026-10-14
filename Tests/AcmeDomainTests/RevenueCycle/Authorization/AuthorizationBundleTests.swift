@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationBundleTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newAuthorizationBundle("code-25", title: "title-424")
        #expect(item.status == RevenueCycle.AuthorizationBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newAuthorizationBundle("code-25", title: "title-424")
        try item.moveTo(RevenueCycle.AuthorizationBundleStatus.suspended)
        #expect(item.status == RevenueCycle.AuthorizationBundleStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newAuthorizationBundle("code-25", title: "title-424")
        item.status = RevenueCycle.AuthorizationBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationBundleStatus.draft) }
    }
}
