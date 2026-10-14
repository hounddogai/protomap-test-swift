@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetThresholdTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newOrderSetThreshold("code-675", title: "title-178")
        #expect(item.status == ClinicalOps.OrderSetThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newOrderSetThreshold("code-675", title: "title-178")
        try item.moveTo(ClinicalOps.OrderSetThresholdStatus.approved)
        #expect(item.status == ClinicalOps.OrderSetThresholdStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newOrderSetThreshold("code-675", title: "title-178")
        item.status = ClinicalOps.OrderSetThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetThresholdStatus.proposed) }
    }
}
