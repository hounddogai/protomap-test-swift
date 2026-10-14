@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftTierTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newShiftTier("code-1", name: "name-169")
        #expect(item.status == Staffing.ShiftTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newShiftTier("code-1", name: "name-169")
        try item.moveTo(Staffing.ShiftTierStatus.granted)
        #expect(item.status == Staffing.ShiftTierStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newShiftTier("code-1", name: "name-169")
        item.status = Staffing.ShiftTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftTierStatus.requested) }
    }
}
