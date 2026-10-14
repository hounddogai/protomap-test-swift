@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultPolicyTests {
    @Test func startsInDraft() throws {
        let item = Labs.newRollingResultPolicy("code-605", name: "name-679")
        #expect(item.status == Labs.RollingResultPolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newRollingResultPolicy("code-605", name: "name-679")
        try item.moveTo(Labs.RollingResultPolicyStatus.active)
        #expect(item.status == Labs.RollingResultPolicyStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newRollingResultPolicy("code-605", name: "name-679")
        item.status = Labs.RollingResultPolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingResultPolicyStatus.draft) }
    }
}
