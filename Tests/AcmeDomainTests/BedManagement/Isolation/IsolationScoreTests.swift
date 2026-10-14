@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationScoreTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newIsolationScore("code-341", title: "title-722")
        #expect(item.status == BedManagement.IsolationScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newIsolationScore("code-341", title: "title-722")
        try item.moveTo(BedManagement.IsolationScoreStatus.active)
        #expect(item.status == BedManagement.IsolationScoreStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newIsolationScore("code-341", title: "title-722")
        item.status = BedManagement.IsolationScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationScoreStatus.draft) }
    }
}
