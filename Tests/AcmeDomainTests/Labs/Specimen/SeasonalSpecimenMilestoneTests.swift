@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalSpecimenMilestoneTests {
    @Test func startsInNew() throws {
        let item = Labs.newSeasonalSpecimenMilestone("code-429", title: "title-545")
        #expect(item.status == Labs.SeasonalSpecimenMilestoneStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newSeasonalSpecimenMilestone("code-429", title: "title-545")
        try item.moveTo(Labs.SeasonalSpecimenMilestoneStatus.running)
        #expect(item.status == Labs.SeasonalSpecimenMilestoneStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSeasonalSpecimenMilestone("code-429", title: "title-545")
        item.status = Labs.SeasonalSpecimenMilestoneStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalSpecimenMilestoneStatus.new) }
    }
}
