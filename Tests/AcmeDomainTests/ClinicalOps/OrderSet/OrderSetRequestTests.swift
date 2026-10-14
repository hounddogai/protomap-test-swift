@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetRequestTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newOrderSetRequest("code-806", label: "label-243")
        #expect(item.status == ClinicalOps.OrderSetRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newOrderSetRequest("code-806", label: "label-243")
        try item.moveTo(ClinicalOps.OrderSetRequestStatus.withdrawn)
        #expect(item.status == ClinicalOps.OrderSetRequestStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newOrderSetRequest("code-806", label: "label-243")
        item.status = ClinicalOps.OrderSetRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetRequestStatus.proposed) }
    }
}
