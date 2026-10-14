@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedSubstitutionAllocationTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newWeightedSubstitutionAllocation("code-810", title: "title-169")
        #expect(item.status == Pharmacy.WeightedSubstitutionAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newWeightedSubstitutionAllocation("code-810", title: "title-169")
        try item.moveTo(Pharmacy.WeightedSubstitutionAllocationStatus.draining)
        #expect(item.status == Pharmacy.WeightedSubstitutionAllocationStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newWeightedSubstitutionAllocation("code-810", title: "title-169")
        item.status = Pharmacy.WeightedSubstitutionAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedSubstitutionAllocationStatus.idle) }
    }
}
