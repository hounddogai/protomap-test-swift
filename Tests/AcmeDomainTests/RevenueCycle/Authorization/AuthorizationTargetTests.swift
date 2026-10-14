@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationTargetTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newAuthorizationTarget("code-678", title: "title-117")
        #expect(item.status == RevenueCycle.AuthorizationTargetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newAuthorizationTarget("code-678", title: "title-117")
        try item.moveTo(RevenueCycle.AuthorizationTargetStatus.queued)
        #expect(item.status == RevenueCycle.AuthorizationTargetStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newAuthorizationTarget("code-678", title: "title-117")
        item.status = RevenueCycle.AuthorizationTargetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationTargetStatus.new) }
    }
}
