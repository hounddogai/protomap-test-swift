@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallPlanTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newLegacyRecallPlan("code-839", name: "name-86")
        #expect(item.status == Pharmacy.LegacyRecallPlanStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newLegacyRecallPlan("code-839", name: "name-86")
        try item.moveTo(Pharmacy.LegacyRecallPlanStatus.inReview)
        #expect(item.status == Pharmacy.LegacyRecallPlanStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newLegacyRecallPlan("code-839", name: "name-86")
        item.status = Pharmacy.LegacyRecallPlanStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyRecallPlanStatus.`open`) }
    }
}
