@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientRoundingTemplateTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newLenientRoundingTemplate("code-112", name: "name-263")
        #expect(item.status == ClinicalOps.LenientRoundingTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newLenientRoundingTemplate("code-112", name: "name-263")
        try item.moveTo(ClinicalOps.LenientRoundingTemplateStatus.granted)
        #expect(item.status == ClinicalOps.LenientRoundingTemplateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newLenientRoundingTemplate("code-112", name: "name-263")
        item.status = ClinicalOps.LenientRoundingTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LenientRoundingTemplateStatus.requested) }
    }
}
