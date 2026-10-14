@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRollupTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newClaimRollup("code-333", name: "name-337")
        #expect(item.status == RevenueCycle.ClaimRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newClaimRollup("code-333", name: "name-337")
        try item.moveTo(RevenueCycle.ClaimRollupStatus.active)
        #expect(item.status == RevenueCycle.ClaimRollupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newClaimRollup("code-333", name: "name-337")
        item.status = RevenueCycle.ClaimRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimRollupStatus.draft) }
    }
}
