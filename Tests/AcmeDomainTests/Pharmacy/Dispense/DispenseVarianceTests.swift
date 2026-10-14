@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseVarianceTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newDispenseVariance("code-861", name: "name-358")
        #expect(item.status == Pharmacy.DispenseVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newDispenseVariance("code-861", name: "name-358")
        try item.moveTo(Pharmacy.DispenseVarianceStatus.rejected)
        #expect(item.status == Pharmacy.DispenseVarianceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newDispenseVariance("code-861", name: "name-358")
        item.status = Pharmacy.DispenseVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseVarianceStatus.proposed) }
    }
}
