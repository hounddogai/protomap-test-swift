@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalGroupTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newGlobalGoalGroup("code-482", title: "title-926")
        #expect(item.status == CareManagement.GlobalGoalGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newGlobalGoalGroup("code-482", title: "title-926")
        try item.moveTo(CareManagement.GlobalGoalGroupStatus.pending)
        #expect(item.status == CareManagement.GlobalGoalGroupStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newGlobalGoalGroup("code-482", title: "title-926")
        item.status = CareManagement.GlobalGoalGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalGoalGroupStatus.draft) }
    }
}
