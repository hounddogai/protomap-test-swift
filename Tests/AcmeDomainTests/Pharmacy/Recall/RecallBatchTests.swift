@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallBatchTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRecallBatch("code-244", label: "label-172")
        #expect(item.status == Pharmacy.RecallBatchStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newRecallBatch("code-244", label: "label-172")
        try item.moveTo(Pharmacy.RecallBatchStatus.completed)
        #expect(item.status == Pharmacy.RecallBatchStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRecallBatch("code-244", label: "label-172")
        item.status = Pharmacy.RecallBatchStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallBatchStatus.planned) }
    }
}
