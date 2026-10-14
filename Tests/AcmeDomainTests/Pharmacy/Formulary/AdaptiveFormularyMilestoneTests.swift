@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyMilestoneTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newAdaptiveFormularyMilestone("code-138", title: "title-177")
        #expect(item.status == Pharmacy.AdaptiveFormularyMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newAdaptiveFormularyMilestone("code-138", title: "title-177")
        try item.moveTo(Pharmacy.AdaptiveFormularyMilestoneStatus.reopened)
        #expect(item.status == Pharmacy.AdaptiveFormularyMilestoneStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newAdaptiveFormularyMilestone("code-138", title: "title-177")
        item.status = Pharmacy.AdaptiveFormularyMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveFormularyMilestoneStatus.`open`) }
    }
}
