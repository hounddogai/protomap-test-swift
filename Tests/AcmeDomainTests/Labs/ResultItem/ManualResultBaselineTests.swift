@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualResultBaselineTests {
    @Test func startsInNew() throws {
        let item = Labs.newManualResultBaseline("code-143", name: "name-248")
        #expect(item.status == Labs.ManualResultBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newManualResultBaseline("code-143", name: "name-248")
        try item.moveTo(Labs.ManualResultBaselineStatus.running)
        #expect(item.status == Labs.ManualResultBaselineStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newManualResultBaseline("code-143", name: "name-248")
        item.status = Labs.ManualResultBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualResultBaselineStatus.new) }
    }
}
