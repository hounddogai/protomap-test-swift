@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalFormularyMilestoneTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRegionalFormularyMilestone("code-526", label: "label-490")
        #expect(item.status == Pharmacy.RegionalFormularyMilestoneStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newRegionalFormularyMilestone("code-526", label: "label-490")
        try item.moveTo(Pharmacy.RegionalFormularyMilestoneStatus.rejected)
        #expect(item.status == Pharmacy.RegionalFormularyMilestoneStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRegionalFormularyMilestone("code-526", label: "label-490")
        item.status = Pharmacy.RegionalFormularyMilestoneStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalFormularyMilestoneStatus.proposed) }
    }
}
