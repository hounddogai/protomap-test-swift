@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledCareGapPolicyTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newScheduledCareGapPolicy("code-881", name: "name-452")
        #expect(item.status == CareManagement.ScheduledCareGapPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newScheduledCareGapPolicy("code-881", name: "name-452")
        try item.moveTo(CareManagement.ScheduledCareGapPolicyStatus.approved)
        #expect(item.status == CareManagement.ScheduledCareGapPolicyStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newScheduledCareGapPolicy("code-881", name: "name-452")
        item.status = CareManagement.ScheduledCareGapPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledCareGapPolicyStatus.proposed) }
    }
}
