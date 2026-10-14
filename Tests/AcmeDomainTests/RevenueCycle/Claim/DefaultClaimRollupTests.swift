@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultClaimRollupTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newDefaultClaimRollup("code-231", name: "name-654")
        #expect(item.status == RevenueCycle.DefaultClaimRollupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newDefaultClaimRollup("code-231", name: "name-654")
        try item.moveTo(RevenueCycle.DefaultClaimRollupStatus.revoked)
        #expect(item.status == RevenueCycle.DefaultClaimRollupStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newDefaultClaimRollup("code-231", name: "name-654")
        item.status = RevenueCycle.DefaultClaimRollupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultClaimRollupStatus.requested) }
    }
}
