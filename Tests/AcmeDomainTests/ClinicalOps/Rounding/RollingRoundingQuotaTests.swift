@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingRoundingQuotaTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newRollingRoundingQuota("code-129", name: "name-253")
        #expect(item.status == ClinicalOps.RollingRoundingQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newRollingRoundingQuota("code-129", name: "name-253")
        try item.moveTo(ClinicalOps.RollingRoundingQuotaStatus.approved)
        #expect(item.status == ClinicalOps.RollingRoundingQuotaStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newRollingRoundingQuota("code-129", name: "name-253")
        item.status = ClinicalOps.RollingRoundingQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingRoundingQuotaStatus.proposed) }
    }
}
