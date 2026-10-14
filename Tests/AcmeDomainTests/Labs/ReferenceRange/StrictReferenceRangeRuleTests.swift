@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictReferenceRangeRuleTests {
    @Test func startsInOpen() throws {
        let item = Labs.newStrictReferenceRangeRule("code-413", name: "name-446")
        #expect(item.status == Labs.StrictReferenceRangeRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Labs.newStrictReferenceRangeRule("code-413", name: "name-446")
        try item.moveTo(Labs.StrictReferenceRangeRuleStatus.archived)
        #expect(item.status == Labs.StrictReferenceRangeRuleStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newStrictReferenceRangeRule("code-413", name: "name-446")
        item.status = Labs.StrictReferenceRangeRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictReferenceRangeRuleStatus.`open`) }
    }
}
