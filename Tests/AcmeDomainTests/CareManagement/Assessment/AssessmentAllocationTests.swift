@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentAllocationTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newAssessmentAllocation("code-869", name: "name-467")
        #expect(item.status == CareManagement.AssessmentAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newAssessmentAllocation("code-869", name: "name-467")
        try item.moveTo(CareManagement.AssessmentAllocationStatus.revoked)
        #expect(item.status == CareManagement.AssessmentAllocationStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newAssessmentAllocation("code-869", name: "name-467")
        item.status = CareManagement.AssessmentAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentAllocationStatus.requested) }
    }
}
