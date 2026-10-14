@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeSegmentTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newRegionalOvertimeSegment("code-429", label: "label-820")
        #expect(item.status == Staffing.RegionalOvertimeSegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newRegionalOvertimeSegment("code-429", label: "label-820")
        try item.moveTo(Staffing.RegionalOvertimeSegmentStatus.published)
        #expect(item.status == Staffing.RegionalOvertimeSegmentStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newRegionalOvertimeSegment("code-429", label: "label-820")
        item.status = Staffing.RegionalOvertimeSegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalOvertimeSegmentStatus.created) }
    }
}
