@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetOverrideTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newOrderSetOverride("code-718", label: "label-953")
        #expect(item.status == ClinicalOps.OrderSetOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newOrderSetOverride("code-718", label: "label-953")
        try item.moveTo(ClinicalOps.OrderSetOverrideStatus.pending)
        #expect(item.status == ClinicalOps.OrderSetOverrideStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newOrderSetOverride("code-718", label: "label-953")
        item.status = ClinicalOps.OrderSetOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetOverrideStatus.draft) }
    }
}
