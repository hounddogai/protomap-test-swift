@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalRoundingTemplateTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newGlobalRoundingTemplate("code-16", name: "name-717")
        #expect(item.status == ClinicalOps.GlobalRoundingTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newGlobalRoundingTemplate("code-16", name: "name-717")
        try item.moveTo(ClinicalOps.GlobalRoundingTemplateStatus.withdrawn)
        #expect(item.status == ClinicalOps.GlobalRoundingTemplateStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newGlobalRoundingTemplate("code-16", name: "name-717")
        item.status = ClinicalOps.GlobalRoundingTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalRoundingTemplateStatus.proposed) }
    }
}
