@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalTaskClaimTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newGlobalTaskClaim("code-674", label: "label-642")
        #expect(item.status == ClinicalOps.GlobalTaskClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newGlobalTaskClaim("code-674", label: "label-642")
        try item.moveTo(ClinicalOps.GlobalTaskClaimStatus.approved)
        #expect(item.status == ClinicalOps.GlobalTaskClaimStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newGlobalTaskClaim("code-674", label: "label-642")
        item.status = ClinicalOps.GlobalTaskClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalTaskClaimStatus.proposed) }
    }
}
