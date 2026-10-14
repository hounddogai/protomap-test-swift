@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetQuotaTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newOrderSetQuota("code-163", label: "label-418")
        #expect(item.status == ClinicalOps.OrderSetQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newOrderSetQuota("code-163", label: "label-418")
        try item.moveTo(ClinicalOps.OrderSetQuotaStatus.published)
        #expect(item.status == ClinicalOps.OrderSetQuotaStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newOrderSetQuota("code-163", label: "label-418")
        item.status = ClinicalOps.OrderSetQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetQuotaStatus.created) }
    }
}
