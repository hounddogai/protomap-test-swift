@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionRuleTests {
    @Test func startsInIdle() throws {
        let item = Labs.newAccessionRule("code-733", name: "name-217")
        #expect(item.status == Labs.AccessionRuleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newAccessionRule("code-733", name: "name-217")
        try item.moveTo(Labs.AccessionRuleStatus.stopped)
        #expect(item.status == Labs.AccessionRuleStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newAccessionRule("code-733", name: "name-217")
        item.status = Labs.AccessionRuleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionRuleStatus.idle) }
    }
}
