@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallDraftTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newWeightedRecallDraft("code-807", name: "name-632")
        #expect(item.status == Pharmacy.WeightedRecallDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newWeightedRecallDraft("code-807", name: "name-632")
        try item.moveTo(Pharmacy.WeightedRecallDraftStatus.rejected)
        #expect(item.status == Pharmacy.WeightedRecallDraftStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newWeightedRecallDraft("code-807", name: "name-632")
        item.status = Pharmacy.WeightedRecallDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedRecallDraftStatus.proposed) }
    }
}
