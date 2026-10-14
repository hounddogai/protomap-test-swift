@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackDischargePlanAllocationTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newFallbackDischargePlanAllocation("code-17", label: "label-258")
        #expect(item.status == BedManagement.FallbackDischargePlanAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newFallbackDischargePlanAllocation("code-17", label: "label-258")
        try item.moveTo(BedManagement.FallbackDischargePlanAllocationStatus.pending)
        #expect(item.status == BedManagement.FallbackDischargePlanAllocationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newFallbackDischargePlanAllocation("code-17", label: "label-258")
        item.status = BedManagement.FallbackDischargePlanAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackDischargePlanAllocationStatus.draft) }
    }
}
