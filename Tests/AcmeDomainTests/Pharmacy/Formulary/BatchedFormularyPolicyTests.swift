@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedFormularyPolicyTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newBatchedFormularyPolicy("code-909", title: "title-707")
        #expect(item.status == Pharmacy.BatchedFormularyPolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newBatchedFormularyPolicy("code-909", title: "title-707")
        try item.moveTo(Pharmacy.BatchedFormularyPolicyStatus.draining)
        #expect(item.status == Pharmacy.BatchedFormularyPolicyStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newBatchedFormularyPolicy("code-909", title: "title-707")
        item.status = Pharmacy.BatchedFormularyPolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedFormularyPolicyStatus.idle) }
    }
}
