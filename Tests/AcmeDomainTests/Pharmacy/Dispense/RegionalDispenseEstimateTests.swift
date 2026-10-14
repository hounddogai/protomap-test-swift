@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalDispenseEstimateTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRegionalDispenseEstimate("code-409", name: "name-588")
        #expect(item.status == Pharmacy.RegionalDispenseEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newRegionalDispenseEstimate("code-409", name: "name-588")
        try item.moveTo(Pharmacy.RegionalDispenseEstimateStatus.inProgress)
        #expect(item.status == Pharmacy.RegionalDispenseEstimateStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRegionalDispenseEstimate("code-409", name: "name-588")
        item.status = Pharmacy.RegionalDispenseEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalDispenseEstimateStatus.planned) }
    }
}
