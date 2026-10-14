@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledBedBoardRuleTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newScheduledBedBoardRule("code-366", name: "name-932")
        #expect(item.status == BedManagement.ScheduledBedBoardRuleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = BedManagement.newScheduledBedBoardRule("code-366", name: "name-932")
        try item.moveTo(BedManagement.ScheduledBedBoardRuleStatus.withdrawn)
        #expect(item.status == BedManagement.ScheduledBedBoardRuleStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newScheduledBedBoardRule("code-366", name: "name-932")
        item.status = BedManagement.ScheduledBedBoardRuleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledBedBoardRuleStatus.proposed) }
    }
}
