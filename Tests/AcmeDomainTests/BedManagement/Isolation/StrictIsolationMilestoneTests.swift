@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationMilestoneTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newStrictIsolationMilestone("code-738", name: "name-939")
        #expect(item.status == BedManagement.StrictIsolationMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newStrictIsolationMilestone("code-738", name: "name-939")
        try item.moveTo(BedManagement.StrictIsolationMilestoneStatus.validated)
        #expect(item.status == BedManagement.StrictIsolationMilestoneStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newStrictIsolationMilestone("code-738", name: "name-939")
        item.status = BedManagement.StrictIsolationMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictIsolationMilestoneStatus.created) }
    }
}
