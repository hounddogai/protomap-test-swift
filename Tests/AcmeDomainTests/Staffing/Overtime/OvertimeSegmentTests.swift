@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSegmentTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newOvertimeSegment("code-553", name: "name-527")
        #expect(item.status == Staffing.OvertimeSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newOvertimeSegment("code-553", name: "name-527")
        try item.moveTo(Staffing.OvertimeSegmentStatus.expired)
        #expect(item.status == Staffing.OvertimeSegmentStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newOvertimeSegment("code-553", name: "name-527")
        item.status = Staffing.OvertimeSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeSegmentStatus.requested) }
    }
}
