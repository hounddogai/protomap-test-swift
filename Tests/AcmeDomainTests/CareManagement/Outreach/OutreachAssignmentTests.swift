@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAssignmentTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newOutreachAssignment("code-494", label: "label-436")
        #expect(item.status == CareManagement.OutreachAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newOutreachAssignment("code-494", label: "label-436")
        try item.moveTo(CareManagement.OutreachAssignmentStatus.pending)
        #expect(item.status == CareManagement.OutreachAssignmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newOutreachAssignment("code-494", label: "label-436")
        item.status = CareManagement.OutreachAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachAssignmentStatus.draft) }
    }
}
