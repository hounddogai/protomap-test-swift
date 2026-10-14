@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseBatchTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newDispenseBatch("code-125", title: "title-881")
        #expect(item.status == Pharmacy.DispenseBatchStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newDispenseBatch("code-125", title: "title-881")
        try item.moveTo(Pharmacy.DispenseBatchStatus.rejected)
        #expect(item.status == Pharmacy.DispenseBatchStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newDispenseBatch("code-125", title: "title-881")
        item.status = Pharmacy.DispenseBatchStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseBatchStatus.proposed) }
    }
}
