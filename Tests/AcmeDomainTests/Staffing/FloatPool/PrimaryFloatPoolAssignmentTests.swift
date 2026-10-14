@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryFloatPoolAssignmentTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newPrimaryFloatPoolAssignment("code-859", label: "label-367")
        #expect(item.status == Staffing.PrimaryFloatPoolAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newPrimaryFloatPoolAssignment("code-859", label: "label-367")
        try item.moveTo(Staffing.PrimaryFloatPoolAssignmentStatus.inReview)
        #expect(item.status == Staffing.PrimaryFloatPoolAssignmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newPrimaryFloatPoolAssignment("code-859", label: "label-367")
        item.status = Staffing.PrimaryFloatPoolAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryFloatPoolAssignmentStatus.`open`) }
    }
}
