@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackOutreachAssignmentTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newFallbackOutreachAssignment("code-126", label: "label-253")
        #expect(item.status == CareManagement.FallbackOutreachAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newFallbackOutreachAssignment("code-126", label: "label-253")
        try item.moveTo(CareManagement.FallbackOutreachAssignmentStatus.revoked)
        #expect(item.status == CareManagement.FallbackOutreachAssignmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newFallbackOutreachAssignment("code-126", label: "label-253")
        item.status = CareManagement.FallbackOutreachAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackOutreachAssignmentStatus.requested) }
    }
}
