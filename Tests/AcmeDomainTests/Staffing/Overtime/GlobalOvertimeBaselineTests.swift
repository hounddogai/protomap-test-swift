@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalOvertimeBaselineTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newGlobalOvertimeBaseline("code-807", label: "label-439")
        #expect(item.status == Staffing.GlobalOvertimeBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newGlobalOvertimeBaseline("code-807", label: "label-439")
        try item.moveTo(Staffing.GlobalOvertimeBaselineStatus.published)
        #expect(item.status == Staffing.GlobalOvertimeBaselineStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newGlobalOvertimeBaseline("code-807", label: "label-439")
        item.status = Staffing.GlobalOvertimeBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalOvertimeBaselineStatus.created) }
    }
}
