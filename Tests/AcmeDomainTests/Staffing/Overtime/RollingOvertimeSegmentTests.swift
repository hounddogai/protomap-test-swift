@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeSegmentTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newRollingOvertimeSegment("code-592", name: "name-840")
        #expect(item.status == Staffing.RollingOvertimeSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newRollingOvertimeSegment("code-592", name: "name-840")
        try item.moveTo(Staffing.RollingOvertimeSegmentStatus.expired)
        #expect(item.status == Staffing.RollingOvertimeSegmentStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newRollingOvertimeSegment("code-592", name: "name-840")
        item.status = Staffing.RollingOvertimeSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingOvertimeSegmentStatus.requested) }
    }
}
