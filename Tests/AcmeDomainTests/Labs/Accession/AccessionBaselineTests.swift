@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionBaselineTests {
    @Test func startsInNew() throws {
        let item = Labs.newAccessionBaseline("code-258", name: "name-186")
        #expect(item.status == Labs.AccessionBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newAccessionBaseline("code-258", name: "name-186")
        try item.moveTo(Labs.AccessionBaselineStatus.queued)
        #expect(item.status == Labs.AccessionBaselineStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newAccessionBaseline("code-258", name: "name-186")
        item.status = Labs.AccessionBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionBaselineStatus.new) }
    }
}
