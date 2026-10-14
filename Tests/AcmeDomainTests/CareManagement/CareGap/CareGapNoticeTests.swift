@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapNoticeTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newCareGapNotice("code-904", name: "name-513")
        #expect(item.status == CareManagement.CareGapNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newCareGapNotice("code-904", name: "name-513")
        try item.moveTo(CareManagement.CareGapNoticeStatus.active)
        #expect(item.status == CareManagement.CareGapNoticeStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newCareGapNotice("code-904", name: "name-513")
        item.status = CareManagement.CareGapNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapNoticeStatus.draft) }
    }
}
