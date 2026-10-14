@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingFormularyBatchTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newPendingFormularyBatch("code-153", label: "label-158")
        #expect(item.status == Pharmacy.PendingFormularyBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newPendingFormularyBatch("code-153", label: "label-158")
        try item.moveTo(Pharmacy.PendingFormularyBatchStatus.running)
        #expect(item.status == Pharmacy.PendingFormularyBatchStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newPendingFormularyBatch("code-153", label: "label-158")
        item.status = Pharmacy.PendingFormularyBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingFormularyBatchStatus.new) }
    }
}
