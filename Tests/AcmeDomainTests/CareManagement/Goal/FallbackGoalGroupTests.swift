@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalGroupTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newFallbackGoalGroup("code-336", title: "title-753")
        #expect(item.status == CareManagement.FallbackGoalGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newFallbackGoalGroup("code-336", title: "title-753")
        try item.moveTo(CareManagement.FallbackGoalGroupStatus.resolved)
        #expect(item.status == CareManagement.FallbackGoalGroupStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newFallbackGoalGroup("code-336", title: "title-753")
        item.status = CareManagement.FallbackGoalGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackGoalGroupStatus.`open`) }
    }
}
