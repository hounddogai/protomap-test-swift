@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryRoundingTemplateTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newPrimaryRoundingTemplate("code-926", title: "title-997")
        #expect(item.status == ClinicalOps.PrimaryRoundingTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = ClinicalOps.newPrimaryRoundingTemplate("code-926", title: "title-997")
        try item.moveTo(ClinicalOps.PrimaryRoundingTemplateStatus.archived)
        #expect(item.status == ClinicalOps.PrimaryRoundingTemplateStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newPrimaryRoundingTemplate("code-926", title: "title-997")
        item.status = ClinicalOps.PrimaryRoundingTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryRoundingTemplateStatus.`open`) }
    }
}
