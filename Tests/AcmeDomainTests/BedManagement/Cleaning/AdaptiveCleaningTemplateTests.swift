@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningTemplateTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newAdaptiveCleaningTemplate("code-964", title: "title-511")
        #expect(item.status == BedManagement.AdaptiveCleaningTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = BedManagement.newAdaptiveCleaningTemplate("code-964", title: "title-511")
        try item.moveTo(BedManagement.AdaptiveCleaningTemplateStatus.archived)
        #expect(item.status == BedManagement.AdaptiveCleaningTemplateStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newAdaptiveCleaningTemplate("code-964", title: "title-511")
        item.status = BedManagement.AdaptiveCleaningTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveCleaningTemplateStatus.`open`) }
    }
}
