@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeScoreTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newRollingOvertimeScore("code-249", label: "label-931")
        #expect(item.status == Staffing.RollingOvertimeScoreStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newRollingOvertimeScore("code-249", label: "label-931")
        try item.moveTo(Staffing.RollingOvertimeScoreStatus.validated)
        #expect(item.status == Staffing.RollingOvertimeScoreStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newRollingOvertimeScore("code-249", label: "label-931")
        item.status = Staffing.RollingOvertimeScoreStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingOvertimeScoreStatus.created) }
    }
}
