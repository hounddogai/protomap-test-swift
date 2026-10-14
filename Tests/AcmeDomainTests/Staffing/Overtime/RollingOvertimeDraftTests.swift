@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeDraftTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newRollingOvertimeDraft("code-870", label: "label-947")
        #expect(item.status == Staffing.RollingOvertimeDraftStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newRollingOvertimeDraft("code-870", label: "label-947")
        try item.moveTo(Staffing.RollingOvertimeDraftStatus.inProgress)
        #expect(item.status == Staffing.RollingOvertimeDraftStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newRollingOvertimeDraft("code-870", label: "label-947")
        item.status = Staffing.RollingOvertimeDraftStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingOvertimeDraftStatus.planned) }
    }
}
