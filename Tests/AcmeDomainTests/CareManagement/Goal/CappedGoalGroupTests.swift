@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedGoalGroupTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newCappedGoalGroup("code-328", label: "label-723")
        #expect(item.status == CareManagement.CappedGoalGroupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newCappedGoalGroup("code-328", label: "label-723")
        try item.moveTo(CareManagement.CappedGoalGroupStatus.warming)
        #expect(item.status == CareManagement.CappedGoalGroupStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newCappedGoalGroup("code-328", label: "label-723")
        item.status = CareManagement.CappedGoalGroupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedGoalGroupStatus.idle) }
    }
}
