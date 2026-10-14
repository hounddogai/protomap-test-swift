@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingTemplateTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newRoundingTemplate("code-408", name: "name-287")
        #expect(item.status == ClinicalOps.RoundingTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newRoundingTemplate("code-408", name: "name-287")
        try item.moveTo(ClinicalOps.RoundingTemplateStatus.pending)
        #expect(item.status == ClinicalOps.RoundingTemplateStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newRoundingTemplate("code-408", name: "name-287")
        item.status = ClinicalOps.RoundingTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingTemplateStatus.draft) }
    }
}
