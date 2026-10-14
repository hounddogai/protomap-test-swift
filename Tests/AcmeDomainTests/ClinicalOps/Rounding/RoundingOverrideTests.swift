@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingOverrideTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newRoundingOverride("code-973", label: "label-841")
        #expect(item.status == ClinicalOps.RoundingOverrideStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newRoundingOverride("code-973", label: "label-841")
        try item.moveTo(ClinicalOps.RoundingOverrideStatus.approved)
        #expect(item.status == ClinicalOps.RoundingOverrideStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newRoundingOverride("code-973", label: "label-841")
        item.status = ClinicalOps.RoundingOverrideStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingOverrideStatus.proposed) }
    }
}
