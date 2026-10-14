@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolTemplateTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newCareProtocolTemplate("code-181", name: "name-435")
        #expect(item.status == ClinicalOps.CareProtocolTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newCareProtocolTemplate("code-181", name: "name-435")
        try item.moveTo(ClinicalOps.CareProtocolTemplateStatus.active)
        #expect(item.status == ClinicalOps.CareProtocolTemplateStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newCareProtocolTemplate("code-181", name: "name-435")
        item.status = ClinicalOps.CareProtocolTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolTemplateStatus.draft) }
    }
}
