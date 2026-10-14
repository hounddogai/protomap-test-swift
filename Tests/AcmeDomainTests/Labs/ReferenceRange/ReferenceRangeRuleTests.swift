@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRuleTests {
    @Test func startsInRequested() throws {
        let item = Labs.newReferenceRangeRule("code-49", label: "label-735")
        #expect(item.status == Labs.ReferenceRangeRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newReferenceRangeRule("code-49", label: "label-735")
        try item.moveTo(Labs.ReferenceRangeRuleStatus.revoked)
        #expect(item.status == Labs.ReferenceRangeRuleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newReferenceRangeRule("code-49", label: "label-735")
        item.status = Labs.ReferenceRangeRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeRuleStatus.requested) }
    }
}
