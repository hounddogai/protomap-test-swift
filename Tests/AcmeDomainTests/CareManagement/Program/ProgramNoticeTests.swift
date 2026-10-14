@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramNoticeTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newProgramNotice("code-819", title: "title-565")
        #expect(item.status == CareManagement.ProgramNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newProgramNotice("code-819", title: "title-565")
        try item.moveTo(CareManagement.ProgramNoticeStatus.pending)
        #expect(item.status == CareManagement.ProgramNoticeStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newProgramNotice("code-819", title: "title-565")
        item.status = CareManagement.ProgramNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramNoticeStatus.draft) }
    }
}
