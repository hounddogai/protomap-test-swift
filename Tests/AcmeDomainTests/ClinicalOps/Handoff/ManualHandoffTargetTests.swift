@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualHandoffTargetTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newManualHandoffTarget("code-953", name: "name-209")
        #expect(item.status == ClinicalOps.ManualHandoffTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newManualHandoffTarget("code-953", name: "name-209")
        try item.moveTo(ClinicalOps.ManualHandoffTargetStatus.approved)
        #expect(item.status == ClinicalOps.ManualHandoffTargetStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newManualHandoffTarget("code-953", name: "name-209")
        item.status = ClinicalOps.ManualHandoffTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ManualHandoffTargetStatus.proposed) }
    }
}
