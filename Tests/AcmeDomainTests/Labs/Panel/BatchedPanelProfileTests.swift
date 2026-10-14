@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedPanelProfileTests {
    @Test func startsInIdle() throws {
        let item = Labs.newBatchedPanelProfile("code-33", title: "title-608")
        #expect(item.status == Labs.BatchedPanelProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newBatchedPanelProfile("code-33", title: "title-608")
        try item.moveTo(Labs.BatchedPanelProfileStatus.stopped)
        #expect(item.status == Labs.BatchedPanelProfileStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newBatchedPanelProfile("code-33", title: "title-608")
        item.status = Labs.BatchedPanelProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedPanelProfileStatus.idle) }
    }
}
