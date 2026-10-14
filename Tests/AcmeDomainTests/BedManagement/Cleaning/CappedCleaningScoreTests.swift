@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningScoreTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newCappedCleaningScore("code-303", label: "label-569")
        #expect(item.status == BedManagement.CappedCleaningScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newCappedCleaningScore("code-303", label: "label-569")
        try item.moveTo(BedManagement.CappedCleaningScoreStatus.scheduled)
        #expect(item.status == BedManagement.CappedCleaningScoreStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newCappedCleaningScore("code-303", label: "label-569")
        item.status = BedManagement.CappedCleaningScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedCleaningScoreStatus.planned) }
    }
}
