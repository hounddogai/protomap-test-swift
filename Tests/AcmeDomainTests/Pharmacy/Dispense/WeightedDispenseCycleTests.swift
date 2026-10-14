@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseCycleTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newWeightedDispenseCycle("code-366", title: "title-898")
        #expect(item.status == Pharmacy.WeightedDispenseCycleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newWeightedDispenseCycle("code-366", title: "title-898")
        try item.moveTo(Pharmacy.WeightedDispenseCycleStatus.inReview)
        #expect(item.status == Pharmacy.WeightedDispenseCycleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newWeightedDispenseCycle("code-366", title: "title-898")
        item.status = Pharmacy.WeightedDispenseCycleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedDispenseCycleStatus.`open`) }
    }
}
