@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimOverrideTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newClaimOverride("code-114", label: "label-974")
        #expect(item.status == RevenueCycle.ClaimOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newClaimOverride("code-114", label: "label-974")
        try item.moveTo(RevenueCycle.ClaimOverrideStatus.stopped)
        #expect(item.status == RevenueCycle.ClaimOverrideStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newClaimOverride("code-114", label: "label-974")
        item.status = RevenueCycle.ClaimOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimOverrideStatus.idle) }
    }
}
