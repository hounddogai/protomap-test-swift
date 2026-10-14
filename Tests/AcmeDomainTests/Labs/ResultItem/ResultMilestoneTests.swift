@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Labs.newResultMilestone("code-603", name: "name-319")
        #expect(item.status == Labs.ResultMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newResultMilestone("code-603", name: "name-319")
        try item.moveTo(Labs.ResultMilestoneStatus.stopped)
        #expect(item.status == Labs.ResultMilestoneStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newResultMilestone("code-603", name: "name-319")
        item.status = Labs.ResultMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultMilestoneStatus.idle) }
    }
}
