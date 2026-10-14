@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationNoticeTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newIsolationNotice("code-752", label: "label-168")
        #expect(item.status == BedManagement.IsolationNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = BedManagement.newIsolationNotice("code-752", label: "label-168")
        try item.moveTo(BedManagement.IsolationNoticeStatus.closed)
        #expect(item.status == BedManagement.IsolationNoticeStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newIsolationNotice("code-752", label: "label-168")
        item.status = BedManagement.IsolationNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationNoticeStatus.draft) }
    }
}
