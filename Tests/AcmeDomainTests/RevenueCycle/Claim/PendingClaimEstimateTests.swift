@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingClaimEstimateTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newPendingClaimEstimate("code-608", label: "label-609")
        #expect(item.status == RevenueCycle.PendingClaimEstimateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newPendingClaimEstimate("code-608", label: "label-609")
        try item.moveTo(RevenueCycle.PendingClaimEstimateStatus.validated)
        #expect(item.status == RevenueCycle.PendingClaimEstimateStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newPendingClaimEstimate("code-608", label: "label-609")
        item.status = RevenueCycle.PendingClaimEstimateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingClaimEstimateStatus.created) }
    }
}
