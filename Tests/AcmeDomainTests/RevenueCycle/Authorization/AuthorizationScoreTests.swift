@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationScoreTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newAuthorizationScore("code-47", title: "title-837")
        #expect(item.status == RevenueCycle.AuthorizationScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newAuthorizationScore("code-47", title: "title-837")
        try item.moveTo(RevenueCycle.AuthorizationScoreStatus.revoked)
        #expect(item.status == RevenueCycle.AuthorizationScoreStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newAuthorizationScore("code-47", title: "title-837")
        item.status = RevenueCycle.AuthorizationScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationScoreStatus.requested) }
    }
}
