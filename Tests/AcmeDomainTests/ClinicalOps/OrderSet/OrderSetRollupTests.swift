@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetRollupTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newOrderSetRollup("code-516", title: "title-387")
        #expect(item.status == ClinicalOps.OrderSetRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newOrderSetRollup("code-516", title: "title-387")
        try item.moveTo(ClinicalOps.OrderSetRollupStatus.done)
        #expect(item.status == ClinicalOps.OrderSetRollupStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newOrderSetRollup("code-516", title: "title-387")
        item.status = ClinicalOps.OrderSetRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetRollupStatus.new) }
    }
}
