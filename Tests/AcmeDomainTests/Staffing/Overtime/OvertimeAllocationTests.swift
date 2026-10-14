@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAllocationTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newOvertimeAllocation("code-538", name: "name-997")
        #expect(item.status == Staffing.OvertimeAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newOvertimeAllocation("code-538", name: "name-997")
        try item.moveTo(Staffing.OvertimeAllocationStatus.inReview)
        #expect(item.status == Staffing.OvertimeAllocationStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newOvertimeAllocation("code-538", name: "name-997")
        item.status = Staffing.OvertimeAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeAllocationStatus.`open`) }
    }
}
