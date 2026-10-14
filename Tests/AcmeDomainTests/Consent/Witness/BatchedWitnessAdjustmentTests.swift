@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessAdjustmentTests {
    @Test func startsInNew() throws {
        let item = Consent.newBatchedWitnessAdjustment("code-386", label: "label-673")
        #expect(item.status == Consent.BatchedWitnessAdjustmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Consent.newBatchedWitnessAdjustment("code-386", label: "label-673")
        try item.moveTo(Consent.BatchedWitnessAdjustmentStatus.done)
        #expect(item.status == Consent.BatchedWitnessAdjustmentStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newBatchedWitnessAdjustment("code-386", label: "label-673")
        item.status = Consent.BatchedWitnessAdjustmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedWitnessAdjustmentStatus.new) }
    }
}
