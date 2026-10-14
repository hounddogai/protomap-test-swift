@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientTaskAllocationTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newLenientTaskAllocation("code-220", title: "title-923")
        #expect(item.status == ClinicalOps.LenientTaskAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newLenientTaskAllocation("code-220", title: "title-923")
        try item.moveTo(ClinicalOps.LenientTaskAllocationStatus.scheduled)
        #expect(item.status == ClinicalOps.LenientTaskAllocationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newLenientTaskAllocation("code-220", title: "title-923")
        item.status = ClinicalOps.LenientTaskAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LenientTaskAllocationStatus.planned) }
    }
}
