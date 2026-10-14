@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAllocationTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newOrderSetAllocation("code-893", label: "label-530")
        #expect(item.status == ClinicalOps.OrderSetAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newOrderSetAllocation("code-893", label: "label-530")
        try item.moveTo(ClinicalOps.OrderSetAllocationStatus.granted)
        #expect(item.status == ClinicalOps.OrderSetAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newOrderSetAllocation("code-893", label: "label-530")
        item.status = ClinicalOps.OrderSetAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetAllocationStatus.requested) }
    }
}
