@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionEstimateTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newSubstitutionEstimate("code-10", name: "name-241")
        #expect(item.status == Pharmacy.SubstitutionEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newSubstitutionEstimate("code-10", name: "name-241")
        try item.moveTo(Pharmacy.SubstitutionEstimateStatus.draining)
        #expect(item.status == Pharmacy.SubstitutionEstimateStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newSubstitutionEstimate("code-10", name: "name-241")
        item.status = Pharmacy.SubstitutionEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionEstimateStatus.idle) }
    }
}
