@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedIsolationScoreTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCappedIsolationScore("code-685", name: "name-600")
        #expect(item.status == BedManagement.CappedIsolationScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = BedManagement.newCappedIsolationScore("code-685", name: "name-600")
        try item.moveTo(BedManagement.CappedIsolationScoreStatus.closed)
        #expect(item.status == BedManagement.CappedIsolationScoreStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCappedIsolationScore("code-685", name: "name-600")
        item.status = BedManagement.CappedIsolationScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedIsolationScoreStatus.draft) }
    }
}
