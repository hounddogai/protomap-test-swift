@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningMilestoneTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCleaningMilestone("code-311", name: "name-172")
        #expect(item.status == BedManagement.CleaningMilestoneStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newCleaningMilestone("code-311", name: "name-172")
        try item.moveTo(BedManagement.CleaningMilestoneStatus.running)
        #expect(item.status == BedManagement.CleaningMilestoneStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCleaningMilestone("code-311", name: "name-172")
        item.status = BedManagement.CleaningMilestoneStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningMilestoneStatus.new) }
    }
}
