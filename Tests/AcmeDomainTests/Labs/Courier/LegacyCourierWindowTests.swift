@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyCourierWindowTests {
    @Test func startsInIdle() throws {
        let item = Labs.newLegacyCourierWindow("code-347", title: "title-751")
        #expect(item.status == Labs.LegacyCourierWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newLegacyCourierWindow("code-347", title: "title-751")
        try item.moveTo(Labs.LegacyCourierWindowStatus.warming)
        #expect(item.status == Labs.LegacyCourierWindowStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newLegacyCourierWindow("code-347", title: "title-751")
        item.status = Labs.LegacyCourierWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyCourierWindowStatus.idle) }
    }
}
