@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimSnapshotTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newAdaptiveClaimSnapshot("code-432", name: "name-739")
        #expect(item.status == RevenueCycle.AdaptiveClaimSnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newAdaptiveClaimSnapshot("code-432", name: "name-739")
        try item.moveTo(RevenueCycle.AdaptiveClaimSnapshotStatus.revoked)
        #expect(item.status == RevenueCycle.AdaptiveClaimSnapshotStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newAdaptiveClaimSnapshot("code-432", name: "name-739")
        item.status = RevenueCycle.AdaptiveClaimSnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveClaimSnapshotStatus.requested) }
    }
}
