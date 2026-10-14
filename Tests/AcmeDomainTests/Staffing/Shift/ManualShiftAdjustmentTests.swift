@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualShiftAdjustmentTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newManualShiftAdjustment("code-777", label: "label-430")
        #expect(item.status == Staffing.ManualShiftAdjustmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newManualShiftAdjustment("code-777", label: "label-430")
        try item.moveTo(Staffing.ManualShiftAdjustmentStatus.granted)
        #expect(item.status == Staffing.ManualShiftAdjustmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newManualShiftAdjustment("code-777", label: "label-430")
        item.status = Staffing.ManualShiftAdjustmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ManualShiftAdjustmentStatus.requested) }
    }
}
