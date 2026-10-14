@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimTierTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newClaimTier("code-408", name: "name-34")
        #expect(item.status == RevenueCycle.ClaimTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newClaimTier("code-408", name: "name-34")
        try item.moveTo(RevenueCycle.ClaimTierStatus.completed)
        #expect(item.status == RevenueCycle.ClaimTierStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newClaimTier("code-408", name: "name-34")
        item.status = RevenueCycle.ClaimTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimTierStatus.planned) }
    }
}
