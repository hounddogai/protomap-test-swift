@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachAssignmentTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newManualOutreachAssignment("code-298", label: "label-76")
        #expect(item.status == CareManagement.ManualOutreachAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newManualOutreachAssignment("code-298", label: "label-76")
        try item.moveTo(CareManagement.ManualOutreachAssignmentStatus.approved)
        #expect(item.status == CareManagement.ManualOutreachAssignmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newManualOutreachAssignment("code-298", label: "label-76")
        item.status = CareManagement.ManualOutreachAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualOutreachAssignmentStatus.proposed) }
    }
}
