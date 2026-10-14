@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultRuleTests {
    @Test func startsInOpen() throws {
        let item = Labs.newPendingResultRule("code-92", name: "name-465")
        #expect(item.status == Labs.PendingResultRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newPendingResultRule("code-92", name: "name-465")
        try item.moveTo(Labs.PendingResultRuleStatus.inReview)
        #expect(item.status == Labs.PendingResultRuleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newPendingResultRule("code-92", name: "name-465")
        item.status = Labs.PendingResultRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingResultRuleStatus.`open`) }
    }
}
