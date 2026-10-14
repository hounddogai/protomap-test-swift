@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newTieredIsolationMilestone("code-161", name: "name-875")
        #expect(item.status == BedManagement.TieredIsolationMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = BedManagement.newTieredIsolationMilestone("code-161", name: "name-875")
        try item.moveTo(BedManagement.TieredIsolationMilestoneStatus.completed)
        #expect(item.status == BedManagement.TieredIsolationMilestoneStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newTieredIsolationMilestone("code-161", name: "name-875")
        item.status = BedManagement.TieredIsolationMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TieredIsolationMilestoneStatus.planned) }
    }
}
