@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedAccessionNoticeTests {
    @Test func startsInIdle() throws {
        let item = Labs.newBatchedAccessionNotice("code-821", name: "name-522")
        #expect(item.status == Labs.BatchedAccessionNoticeStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newBatchedAccessionNotice("code-821", name: "name-522")
        try item.moveTo(Labs.BatchedAccessionNoticeStatus.stopped)
        #expect(item.status == Labs.BatchedAccessionNoticeStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newBatchedAccessionNotice("code-821", name: "name-522")
        item.status = Labs.BatchedAccessionNoticeStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedAccessionNoticeStatus.idle) }
    }
}
