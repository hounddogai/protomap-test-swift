@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationWindowTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newBatchedIsolationWindow("code-186", label: "label-296")
        #expect(item.status == BedManagement.BatchedIsolationWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newBatchedIsolationWindow("code-186", label: "label-296")
        try item.moveTo(BedManagement.BatchedIsolationWindowStatus.ready)
        #expect(item.status == BedManagement.BatchedIsolationWindowStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newBatchedIsolationWindow("code-186", label: "label-296")
        item.status = BedManagement.BatchedIsolationWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedIsolationWindowStatus.idle) }
    }
}
