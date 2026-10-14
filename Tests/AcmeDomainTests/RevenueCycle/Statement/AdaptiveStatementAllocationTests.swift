@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementAllocationTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newAdaptiveStatementAllocation("code-951", title: "title-380")
        #expect(item.status == RevenueCycle.AdaptiveStatementAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newAdaptiveStatementAllocation("code-951", title: "title-380")
        try item.moveTo(RevenueCycle.AdaptiveStatementAllocationStatus.withdrawn)
        #expect(item.status == RevenueCycle.AdaptiveStatementAllocationStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newAdaptiveStatementAllocation("code-951", title: "title-380")
        item.status = RevenueCycle.AdaptiveStatementAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveStatementAllocationStatus.proposed) }
    }
}
