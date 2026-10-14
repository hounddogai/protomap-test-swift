@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalCredentialMilestoneTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newGlobalCredentialMilestone("code-137", title: "title-408")
        #expect(item.status == Staffing.GlobalCredentialMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newGlobalCredentialMilestone("code-137", title: "title-408")
        try item.moveTo(Staffing.GlobalCredentialMilestoneStatus.revoked)
        #expect(item.status == Staffing.GlobalCredentialMilestoneStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newGlobalCredentialMilestone("code-137", title: "title-408")
        item.status = Staffing.GlobalCredentialMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalCredentialMilestoneStatus.requested) }
    }
}
