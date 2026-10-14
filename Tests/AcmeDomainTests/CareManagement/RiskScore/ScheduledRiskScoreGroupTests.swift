@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledRiskScoreGroupTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newScheduledRiskScoreGroup("code-86", name: "name-82")
        #expect(item.status == CareManagement.ScheduledRiskScoreGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newScheduledRiskScoreGroup("code-86", name: "name-82")
        try item.moveTo(CareManagement.ScheduledRiskScoreGroupStatus.approved)
        #expect(item.status == CareManagement.ScheduledRiskScoreGroupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newScheduledRiskScoreGroup("code-86", name: "name-82")
        item.status = CareManagement.ScheduledRiskScoreGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledRiskScoreGroupStatus.proposed) }
    }
}
