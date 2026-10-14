@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningNoticeTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCleaningNotice("code-698", label: "label-747")
        #expect(item.status == BedManagement.CleaningNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = BedManagement.newCleaningNotice("code-698", label: "label-747")
        try item.moveTo(BedManagement.CleaningNoticeStatus.failed)
        #expect(item.status == BedManagement.CleaningNoticeStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCleaningNotice("code-698", label: "label-747")
        item.status = BedManagement.CleaningNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningNoticeStatus.new) }
    }
}
