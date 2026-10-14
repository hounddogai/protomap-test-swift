@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftScoreTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newTieredShiftScore("code-338", name: "name-417")
        #expect(item.status == Staffing.TieredShiftScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newTieredShiftScore("code-338", name: "name-417")
        try item.moveTo(Staffing.TieredShiftScoreStatus.scheduled)
        #expect(item.status == Staffing.TieredShiftScoreStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newTieredShiftScore("code-338", name: "name-417")
        item.status = Staffing.TieredShiftScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredShiftScoreStatus.planned) }
    }
}
