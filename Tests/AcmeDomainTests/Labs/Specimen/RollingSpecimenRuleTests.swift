@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenRuleTests {
    @Test func startsInDraft() throws {
        let item = Labs.newRollingSpecimenRule("code-544", name: "name-384")
        #expect(item.status == Labs.RollingSpecimenRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newRollingSpecimenRule("code-544", name: "name-384")
        try item.moveTo(Labs.RollingSpecimenRuleStatus.closed)
        #expect(item.status == Labs.RollingSpecimenRuleStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newRollingSpecimenRule("code-544", name: "name-384")
        item.status = Labs.RollingSpecimenRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingSpecimenRuleStatus.draft) }
    }
}
