@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffTemplateTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newHandoffTemplate("code-287", name: "name-155")
        #expect(item.status == ClinicalOps.HandoffTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newHandoffTemplate("code-287", name: "name-155")
        try item.moveTo(ClinicalOps.HandoffTemplateStatus.approved)
        #expect(item.status == ClinicalOps.HandoffTemplateStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newHandoffTemplate("code-287", name: "name-155")
        item.status = ClinicalOps.HandoffTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffTemplateStatus.proposed) }
    }
}
