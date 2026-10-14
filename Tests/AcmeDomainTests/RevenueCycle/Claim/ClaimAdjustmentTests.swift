@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimAdjustmentTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newClaimAdjustment("code-274", label: "label-242")
        #expect(item.status == RevenueCycle.ClaimAdjustmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newClaimAdjustment("code-274", label: "label-242")
        try item.moveTo(RevenueCycle.ClaimAdjustmentStatus.retired)
        #expect(item.status == RevenueCycle.ClaimAdjustmentStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newClaimAdjustment("code-274", label: "label-242")
        item.status = RevenueCycle.ClaimAdjustmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimAdjustmentStatus.created) }
    }
}
