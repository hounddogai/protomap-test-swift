@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyBatchTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newFormularyBatch("code-660", title: "title-999")
        #expect(item.status == Pharmacy.FormularyBatchStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newFormularyBatch("code-660", title: "title-999")
        try item.moveTo(Pharmacy.FormularyBatchStatus.resolved)
        #expect(item.status == Pharmacy.FormularyBatchStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newFormularyBatch("code-660", title: "title-999")
        item.status = Pharmacy.FormularyBatchStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyBatchStatus.`open`) }
    }
}
