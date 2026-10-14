@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredResultPolicyTests {
    @Test func startsInNew() throws {
        let item = Labs.newTieredResultPolicy("code-156", title: "title-157")
        #expect(item.status == Labs.TieredResultPolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newTieredResultPolicy("code-156", title: "title-157")
        try item.moveTo(Labs.TieredResultPolicyStatus.running)
        #expect(item.status == Labs.TieredResultPolicyStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newTieredResultPolicy("code-156", title: "title-157")
        item.status = Labs.TieredResultPolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.TieredResultPolicyStatus.new) }
    }
}
