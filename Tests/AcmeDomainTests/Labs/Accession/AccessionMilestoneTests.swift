@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionMilestoneTests {
    @Test func startsInDraft() throws {
        let item = Labs.newAccessionMilestone("code-7", name: "name-844")
        #expect(item.status == Labs.AccessionMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newAccessionMilestone("code-7", name: "name-844")
        try item.moveTo(Labs.AccessionMilestoneStatus.active)
        #expect(item.status == Labs.AccessionMilestoneStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newAccessionMilestone("code-7", name: "name-844")
        item.status = Labs.AccessionMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionMilestoneStatus.draft) }
    }
}
