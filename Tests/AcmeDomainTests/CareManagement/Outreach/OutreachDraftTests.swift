@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachDraftTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newOutreachDraft("code-153", title: "title-281")
        #expect(item.status == CareManagement.OutreachDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newOutreachDraft("code-153", title: "title-281")
        try item.moveTo(CareManagement.OutreachDraftStatus.reopened)
        #expect(item.status == CareManagement.OutreachDraftStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newOutreachDraft("code-153", title: "title-281")
        item.status = CareManagement.OutreachDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachDraftStatus.`open`) }
    }
}
