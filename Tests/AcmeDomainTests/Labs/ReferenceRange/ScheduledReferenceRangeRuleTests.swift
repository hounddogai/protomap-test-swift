@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledReferenceRangeRuleTests {
    @Test func startsInDraft() throws {
        let item = Labs.newScheduledReferenceRangeRule("code-496", name: "name-784")
        #expect(item.status == Labs.ScheduledReferenceRangeRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newScheduledReferenceRangeRule("code-496", name: "name-784")
        try item.moveTo(Labs.ScheduledReferenceRangeRuleStatus.pending)
        #expect(item.status == Labs.ScheduledReferenceRangeRuleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newScheduledReferenceRangeRule("code-496", name: "name-784")
        item.status = Labs.ScheduledReferenceRangeRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledReferenceRangeRuleStatus.draft) }
    }
}
