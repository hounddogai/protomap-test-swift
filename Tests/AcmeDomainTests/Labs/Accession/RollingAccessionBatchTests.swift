@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionBatchTests {
    @Test func startsInIdle() throws {
        let item = Labs.newRollingAccessionBatch("code-14", title: "title-90")
        #expect(item.status == Labs.RollingAccessionBatchStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newRollingAccessionBatch("code-14", title: "title-90")
        try item.moveTo(Labs.RollingAccessionBatchStatus.stopped)
        #expect(item.status == Labs.RollingAccessionBatchStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newRollingAccessionBatch("code-14", title: "title-90")
        item.status = Labs.RollingAccessionBatchStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingAccessionBatchStatus.idle) }
    }
}
