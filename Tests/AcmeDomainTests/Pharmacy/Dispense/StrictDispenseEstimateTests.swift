@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictDispenseEstimateTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newStrictDispenseEstimate("code-962", name: "name-782")
        #expect(item.status == Pharmacy.StrictDispenseEstimateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newStrictDispenseEstimate("code-962", name: "name-782")
        try item.moveTo(Pharmacy.StrictDispenseEstimateStatus.approved)
        #expect(item.status == Pharmacy.StrictDispenseEstimateStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newStrictDispenseEstimate("code-962", name: "name-782")
        item.status = Pharmacy.StrictDispenseEstimateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictDispenseEstimateStatus.proposed) }
    }
}
