@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetPolicyTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newOrderSetPolicy("code-7", label: "label-35")
        #expect(item.status == ClinicalOps.OrderSetPolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newOrderSetPolicy("code-7", label: "label-35")
        try item.moveTo(ClinicalOps.OrderSetPolicyStatus.pending)
        #expect(item.status == ClinicalOps.OrderSetPolicyStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newOrderSetPolicy("code-7", label: "label-35")
        item.status = ClinicalOps.OrderSetPolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetPolicyStatus.draft) }
    }
}
