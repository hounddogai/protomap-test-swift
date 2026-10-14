@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachEntryTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newPrimaryOutreachEntry("code-117", title: "title-219")
        #expect(item.status == CareManagement.PrimaryOutreachEntryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newPrimaryOutreachEntry("code-117", title: "title-219")
        try item.moveTo(CareManagement.PrimaryOutreachEntryStatus.reopened)
        #expect(item.status == CareManagement.PrimaryOutreachEntryStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newPrimaryOutreachEntry("code-117", title: "title-219")
        item.status = CareManagement.PrimaryOutreachEntryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryOutreachEntryStatus.`open`) }
    }
}
