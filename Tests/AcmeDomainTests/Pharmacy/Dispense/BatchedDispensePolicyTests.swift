@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispensePolicyTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newBatchedDispensePolicy("code-298", title: "title-760")
        #expect(item.status == Pharmacy.BatchedDispensePolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newBatchedDispensePolicy("code-298", title: "title-760")
        try item.moveTo(Pharmacy.BatchedDispensePolicyStatus.pending)
        #expect(item.status == Pharmacy.BatchedDispensePolicyStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newBatchedDispensePolicy("code-298", title: "title-760")
        item.status = Pharmacy.BatchedDispensePolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedDispensePolicyStatus.draft) }
    }
}
