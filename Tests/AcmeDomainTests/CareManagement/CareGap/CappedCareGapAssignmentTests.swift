@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapAssignmentTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCappedCareGapAssignment("code-217", label: "label-197")
        #expect(item.status == CareManagement.CappedCareGapAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newCappedCareGapAssignment("code-217", label: "label-197")
        try item.moveTo(CareManagement.CappedCareGapAssignmentStatus.reopened)
        #expect(item.status == CareManagement.CappedCareGapAssignmentStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCappedCareGapAssignment("code-217", label: "label-197")
        item.status = CareManagement.CappedCareGapAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedCareGapAssignmentStatus.`open`) }
    }
}
