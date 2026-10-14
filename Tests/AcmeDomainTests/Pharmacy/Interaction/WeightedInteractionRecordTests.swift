@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInteractionRecordTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newWeightedInteractionRecord("code-721", title: "title-293")
        #expect(item.status == Pharmacy.WeightedInteractionRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newWeightedInteractionRecord("code-721", title: "title-293")
        try item.moveTo(Pharmacy.WeightedInteractionRecordStatus.approved)
        #expect(item.status == Pharmacy.WeightedInteractionRecordStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newWeightedInteractionRecord("code-721", title: "title-293")
        item.status = Pharmacy.WeightedInteractionRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedInteractionRecordStatus.proposed) }
    }
}
