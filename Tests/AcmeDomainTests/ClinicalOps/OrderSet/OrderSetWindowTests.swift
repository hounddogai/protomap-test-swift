@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetWindowTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newOrderSetWindow("code-968", title: "title-471")
        #expect(item.status == ClinicalOps.OrderSetWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newOrderSetWindow("code-968", title: "title-471")
        try item.moveTo(ClinicalOps.OrderSetWindowStatus.pending)
        #expect(item.status == ClinicalOps.OrderSetWindowStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newOrderSetWindow("code-968", title: "title-471")
        item.status = ClinicalOps.OrderSetWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetWindowStatus.draft) }
    }
}
