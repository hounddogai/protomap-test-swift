@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationCheckpointTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newAuthorizationCheckpoint("code-337", title: "title-272")
        #expect(item.status == RevenueCycle.AuthorizationCheckpointStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newAuthorizationCheckpoint("code-337", title: "title-272")
        try item.moveTo(RevenueCycle.AuthorizationCheckpointStatus.revoked)
        #expect(item.status == RevenueCycle.AuthorizationCheckpointStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newAuthorizationCheckpoint("code-337", title: "title-272")
        item.status = RevenueCycle.AuthorizationCheckpointStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationCheckpointStatus.requested) }
    }
}
