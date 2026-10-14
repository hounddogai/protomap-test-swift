@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeEstimateTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newOvertimeEstimate("code-387", label: "label-39")
        #expect(item.status == Staffing.OvertimeEstimateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newOvertimeEstimate("code-387", label: "label-39")
        try item.moveTo(Staffing.OvertimeEstimateStatus.published)
        #expect(item.status == Staffing.OvertimeEstimateStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newOvertimeEstimate("code-387", label: "label-39")
        item.status = Staffing.OvertimeEstimateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeEstimateStatus.created) }
    }
}
