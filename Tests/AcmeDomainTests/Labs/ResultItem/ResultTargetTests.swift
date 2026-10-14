@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultTargetTests {
    @Test func startsInIdle() throws {
        let item = Labs.newResultTarget("code-61", name: "name-229")
        #expect(item.status == Labs.ResultTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newResultTarget("code-61", name: "name-229")
        try item.moveTo(Labs.ResultTargetStatus.stopped)
        #expect(item.status == Labs.ResultTargetStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newResultTarget("code-61", name: "name-229")
        item.status = Labs.ResultTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultTargetStatus.idle) }
    }
}
