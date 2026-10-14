@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetDraftTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newOrderSetDraft("code-538", title: "title-779")
        #expect(item.status == ClinicalOps.OrderSetDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newOrderSetDraft("code-538", title: "title-779")
        try item.moveTo(ClinicalOps.OrderSetDraftStatus.withdrawn)
        #expect(item.status == ClinicalOps.OrderSetDraftStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newOrderSetDraft("code-538", title: "title-779")
        item.status = ClinicalOps.OrderSetDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetDraftStatus.proposed) }
    }
}
