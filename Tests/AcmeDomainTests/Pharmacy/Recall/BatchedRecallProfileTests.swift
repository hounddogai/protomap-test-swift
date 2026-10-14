@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedRecallProfileTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newBatchedRecallProfile("code-583", label: "label-317")
        #expect(item.status == Pharmacy.BatchedRecallProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newBatchedRecallProfile("code-583", label: "label-317")
        try item.moveTo(Pharmacy.BatchedRecallProfileStatus.ready)
        #expect(item.status == Pharmacy.BatchedRecallProfileStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newBatchedRecallProfile("code-583", label: "label-317")
        item.status = Pharmacy.BatchedRecallProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedRecallProfileStatus.idle) }
    }
}
