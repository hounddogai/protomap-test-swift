@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimAllocationTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newAdaptiveClaimAllocation("code-92", name: "name-663")
        #expect(item.status == RevenueCycle.AdaptiveClaimAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newAdaptiveClaimAllocation("code-92", name: "name-663")
        try item.moveTo(RevenueCycle.AdaptiveClaimAllocationStatus.reopened)
        #expect(item.status == RevenueCycle.AdaptiveClaimAllocationStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newAdaptiveClaimAllocation("code-92", name: "name-663")
        item.status = RevenueCycle.AdaptiveClaimAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveClaimAllocationStatus.`open`) }
    }
}
