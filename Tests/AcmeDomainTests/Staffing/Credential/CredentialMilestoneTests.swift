@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newCredentialMilestone("code-93", label: "label-139")
        #expect(item.status == Staffing.CredentialMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newCredentialMilestone("code-93", label: "label-139")
        try item.moveTo(Staffing.CredentialMilestoneStatus.ready)
        #expect(item.status == Staffing.CredentialMilestoneStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newCredentialMilestone("code-93", label: "label-139")
        item.status = Staffing.CredentialMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialMilestoneStatus.idle) }
    }
}
