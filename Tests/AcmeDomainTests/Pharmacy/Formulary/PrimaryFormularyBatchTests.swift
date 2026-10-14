@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryFormularyBatchTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newPrimaryFormularyBatch("code-83", title: "title-839")
        #expect(item.status == Pharmacy.PrimaryFormularyBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newPrimaryFormularyBatch("code-83", title: "title-839")
        try item.moveTo(Pharmacy.PrimaryFormularyBatchStatus.done)
        #expect(item.status == Pharmacy.PrimaryFormularyBatchStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newPrimaryFormularyBatch("code-83", title: "title-839")
        item.status = Pharmacy.PrimaryFormularyBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryFormularyBatchStatus.new) }
    }
}
