@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetNoticeTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newOrderSetNotice("code-976", name: "name-2")
        #expect(item.status == ClinicalOps.OrderSetNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newOrderSetNotice("code-976", name: "name-2")
        try item.moveTo(ClinicalOps.OrderSetNoticeStatus.withdrawn)
        #expect(item.status == ClinicalOps.OrderSetNoticeStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newOrderSetNotice("code-976", name: "name-2")
        item.status = ClinicalOps.OrderSetNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetNoticeStatus.proposed) }
    }
}
