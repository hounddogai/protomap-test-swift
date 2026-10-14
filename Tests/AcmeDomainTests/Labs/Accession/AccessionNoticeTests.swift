@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionNoticeTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newAccessionNotice("code-65", label: "label-572")
        #expect(item.status == Labs.AccessionNoticeStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newAccessionNotice("code-65", label: "label-572")
        try item.moveTo(Labs.AccessionNoticeStatus.inProgress)
        #expect(item.status == Labs.AccessionNoticeStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newAccessionNotice("code-65", label: "label-572")
        item.status = Labs.AccessionNoticeStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionNoticeStatus.planned) }
    }
}
