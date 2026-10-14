@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingAuthorizationCheckpointTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRollingAuthorizationCheckpoint("code-515", name: "name-873")
        #expect(item.status == RevenueCycle.RollingAuthorizationCheckpointStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newRollingAuthorizationCheckpoint("code-515", name: "name-873")
        try item.moveTo(RevenueCycle.RollingAuthorizationCheckpointStatus.revoked)
        #expect(item.status == RevenueCycle.RollingAuthorizationCheckpointStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRollingAuthorizationCheckpoint("code-515", name: "name-873")
        item.status = RevenueCycle.RollingAuthorizationCheckpointStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingAuthorizationCheckpointStatus.requested) }
    }
}
