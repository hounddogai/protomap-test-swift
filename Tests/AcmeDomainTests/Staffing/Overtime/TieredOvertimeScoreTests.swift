@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredOvertimeScoreTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newTieredOvertimeScore("code-631", label: "label-802")
        #expect(item.status == Staffing.TieredOvertimeScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Staffing.newTieredOvertimeScore("code-631", label: "label-802")
        try item.moveTo(Staffing.TieredOvertimeScoreStatus.completed)
        #expect(item.status == Staffing.TieredOvertimeScoreStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newTieredOvertimeScore("code-631", label: "label-802")
        item.status = Staffing.TieredOvertimeScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredOvertimeScoreStatus.planned) }
    }
}
