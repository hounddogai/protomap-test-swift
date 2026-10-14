@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningTemplateTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newFallbackCleaningTemplate("code-189", name: "name-289")
        #expect(item.status == BedManagement.FallbackCleaningTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newFallbackCleaningTemplate("code-189", name: "name-289")
        try item.moveTo(BedManagement.FallbackCleaningTemplateStatus.reopened)
        #expect(item.status == BedManagement.FallbackCleaningTemplateStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newFallbackCleaningTemplate("code-189", name: "name-289")
        item.status = BedManagement.FallbackCleaningTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackCleaningTemplateStatus.`open`) }
    }
}
