@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictGoalGroupTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newStrictGoalGroup("code-750", name: "name-44")
        #expect(item.status == CareManagement.StrictGoalGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newStrictGoalGroup("code-750", name: "name-44")
        try item.moveTo(CareManagement.StrictGoalGroupStatus.active)
        #expect(item.status == CareManagement.StrictGoalGroupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newStrictGoalGroup("code-750", name: "name-44")
        item.status = CareManagement.StrictGoalGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.StrictGoalGroupStatus.draft) }
    }
}
