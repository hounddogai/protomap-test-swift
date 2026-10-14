@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusMilestoneTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newScheduledCensusMilestone("code-879", name: "name-533")
        #expect(item.status == BedManagement.ScheduledCensusMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newScheduledCensusMilestone("code-879", name: "name-533")
        try item.moveTo(BedManagement.ScheduledCensusMilestoneStatus.validated)
        #expect(item.status == BedManagement.ScheduledCensusMilestoneStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newScheduledCensusMilestone("code-879", name: "name-533")
        item.status = BedManagement.ScheduledCensusMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCensusMilestoneStatus.created) }
    }
}
