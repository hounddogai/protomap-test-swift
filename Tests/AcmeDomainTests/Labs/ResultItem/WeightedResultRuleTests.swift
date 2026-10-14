@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedResultRuleTests {
    @Test func startsInDraft() throws {
        let item = Labs.newWeightedResultRule("code-243", name: "name-510")
        #expect(item.status == Labs.WeightedResultRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newWeightedResultRule("code-243", name: "name-510")
        try item.moveTo(Labs.WeightedResultRuleStatus.pending)
        #expect(item.status == Labs.WeightedResultRuleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newWeightedResultRule("code-243", name: "name-510")
        item.status = Labs.WeightedResultRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedResultRuleStatus.draft) }
    }
}
