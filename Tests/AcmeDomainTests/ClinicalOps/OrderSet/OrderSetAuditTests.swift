@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAuditTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newOrderSetAudit("code-577", name: "name-351")
        #expect(item.status == ClinicalOps.OrderSetAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newOrderSetAudit("code-577", name: "name-351")
        try item.moveTo(ClinicalOps.OrderSetAuditStatus.revoked)
        #expect(item.status == ClinicalOps.OrderSetAuditStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newOrderSetAudit("code-577", name: "name-351")
        item.status = ClinicalOps.OrderSetAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetAuditStatus.requested) }
    }
}
