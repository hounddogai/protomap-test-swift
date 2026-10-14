@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryCareGapNoticeTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newPrimaryCareGapNotice("code-940", name: "name-405")
        #expect(item.status == CareManagement.PrimaryCareGapNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newPrimaryCareGapNotice("code-940", name: "name-405")
        try item.moveTo(CareManagement.PrimaryCareGapNoticeStatus.active)
        #expect(item.status == CareManagement.PrimaryCareGapNoticeStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newPrimaryCareGapNotice("code-940", name: "name-405")
        item.status = CareManagement.PrimaryCareGapNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryCareGapNoticeStatus.draft) }
    }
}
