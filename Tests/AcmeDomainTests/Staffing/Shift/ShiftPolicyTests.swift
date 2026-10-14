@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftPolicyTests {
    @Test func startsInNew() throws {
        let item = Staffing.newShiftPolicy("code-615", label: "label-680")
        #expect(item.status == Staffing.ShiftPolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newShiftPolicy("code-615", label: "label-680")
        try item.moveTo(Staffing.ShiftPolicyStatus.running)
        #expect(item.status == Staffing.ShiftPolicyStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newShiftPolicy("code-615", label: "label-680")
        item.status = Staffing.ShiftPolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftPolicyStatus.new) }
    }
}
