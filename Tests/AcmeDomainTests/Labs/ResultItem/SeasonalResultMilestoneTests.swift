@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalResultMilestoneTests {
    @Test func startsInDraft() throws {
        let item = Labs.newSeasonalResultMilestone("code-261", name: "name-164")
        #expect(item.status == Labs.SeasonalResultMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newSeasonalResultMilestone("code-261", name: "name-164")
        try item.moveTo(Labs.SeasonalResultMilestoneStatus.active)
        #expect(item.status == Labs.SeasonalResultMilestoneStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newSeasonalResultMilestone("code-261", name: "name-164")
        item.status = Labs.SeasonalResultMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalResultMilestoneStatus.draft) }
    }
}
