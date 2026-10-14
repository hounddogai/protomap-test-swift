@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryTaskTemplateTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newPrimaryTaskTemplate("code-486", name: "name-114")
        #expect(item.status == ClinicalOps.PrimaryTaskTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newPrimaryTaskTemplate("code-486", name: "name-114")
        try item.moveTo(ClinicalOps.PrimaryTaskTemplateStatus.reopened)
        #expect(item.status == ClinicalOps.PrimaryTaskTemplateStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newPrimaryTaskTemplate("code-486", name: "name-114")
        item.status = ClinicalOps.PrimaryTaskTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryTaskTemplateStatus.`open`) }
    }
}
