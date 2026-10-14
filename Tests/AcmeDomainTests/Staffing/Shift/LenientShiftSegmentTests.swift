@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientShiftSegmentTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newLenientShiftSegment("code-340", title: "title-366")
        #expect(item.status == Staffing.LenientShiftSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newLenientShiftSegment("code-340", title: "title-366")
        try item.moveTo(Staffing.LenientShiftSegmentStatus.granted)
        #expect(item.status == Staffing.LenientShiftSegmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newLenientShiftSegment("code-340", title: "title-366")
        item.status = Staffing.LenientShiftSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientShiftSegmentStatus.requested) }
    }
}
