@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackRemittanceBundleTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newFallbackRemittanceBundle("code-593", label: "label-338")
        #expect(item.status == RevenueCycle.FallbackRemittanceBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newFallbackRemittanceBundle("code-593", label: "label-338")
        try item.moveTo(RevenueCycle.FallbackRemittanceBundleStatus.approved)
        #expect(item.status == RevenueCycle.FallbackRemittanceBundleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newFallbackRemittanceBundle("code-593", label: "label-338")
        item.status = RevenueCycle.FallbackRemittanceBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackRemittanceBundleStatus.proposed) }
    }
}
