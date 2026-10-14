@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultReferenceRangeRuleTests {
    @Test func startsInProposed() throws {
        let item = Labs.newDefaultReferenceRangeRule("code-147", title: "title-495")
        #expect(item.status == Labs.DefaultReferenceRangeRuleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newDefaultReferenceRangeRule("code-147", title: "title-495")
        try item.moveTo(Labs.DefaultReferenceRangeRuleStatus.approved)
        #expect(item.status == Labs.DefaultReferenceRangeRuleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newDefaultReferenceRangeRule("code-147", title: "title-495")
        item.status = Labs.DefaultReferenceRangeRuleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultReferenceRangeRuleStatus.proposed) }
    }
}
