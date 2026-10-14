@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftSegmentTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newShiftSegment("code-969", label: "label-856")
        #expect(item.status == Staffing.ShiftSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newShiftSegment("code-969", label: "label-856")
        try item.moveTo(Staffing.ShiftSegmentStatus.granted)
        #expect(item.status == Staffing.ShiftSegmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newShiftSegment("code-969", label: "label-856")
        item.status = Staffing.ShiftSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftSegmentStatus.requested) }
    }
}
