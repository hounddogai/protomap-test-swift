@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedAccessionRuleTests {
    @Test func startsInDraft() throws {
        let item = Labs.newWeightedAccessionRule("code-788", title: "title-174")
        #expect(item.status == Labs.WeightedAccessionRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newWeightedAccessionRule("code-788", title: "title-174")
        try item.moveTo(Labs.WeightedAccessionRuleStatus.active)
        #expect(item.status == Labs.WeightedAccessionRuleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newWeightedAccessionRule("code-788", title: "title-174")
        item.status = Labs.WeightedAccessionRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedAccessionRuleStatus.draft) }
    }
}
