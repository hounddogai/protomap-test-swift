@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierBatchTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCourierBatch("code-416", label: "label-450")
        #expect(item.status == Labs.CourierBatchStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newCourierBatch("code-416", label: "label-450")
        try item.moveTo(Labs.CourierBatchStatus.ready)
        #expect(item.status == Labs.CourierBatchStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCourierBatch("code-416", label: "label-450")
        item.status = Labs.CourierBatchStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierBatchStatus.idle) }
    }
}
