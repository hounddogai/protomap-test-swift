@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedCredentialMilestoneTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newCappedCredentialMilestone("code-230", title: "title-128")
        #expect(item.status == Staffing.CappedCredentialMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Staffing.newCappedCredentialMilestone("code-230", title: "title-128")
        try item.moveTo(Staffing.CappedCredentialMilestoneStatus.archived)
        #expect(item.status == Staffing.CappedCredentialMilestoneStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newCappedCredentialMilestone("code-230", title: "title-128")
        item.status = Staffing.CappedCredentialMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedCredentialMilestoneStatus.`open`) }
    }
}
