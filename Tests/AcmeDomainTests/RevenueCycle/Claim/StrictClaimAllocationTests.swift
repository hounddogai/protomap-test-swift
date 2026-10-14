@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictClaimAllocationTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newStrictClaimAllocation("code-993", label: "label-945")
        #expect(item.status == RevenueCycle.StrictClaimAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newStrictClaimAllocation("code-993", label: "label-945")
        try item.moveTo(RevenueCycle.StrictClaimAllocationStatus.scheduled)
        #expect(item.status == RevenueCycle.StrictClaimAllocationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newStrictClaimAllocation("code-993", label: "label-945")
        item.status = RevenueCycle.StrictClaimAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictClaimAllocationStatus.planned) }
    }
}
