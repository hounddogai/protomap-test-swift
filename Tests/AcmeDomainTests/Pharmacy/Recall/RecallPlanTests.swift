@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallPlanTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRecallPlan("code-589", title: "title-364")
        #expect(item.status == Pharmacy.RecallPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Pharmacy.newRecallPlan("code-589", title: "title-364")
        try item.moveTo(Pharmacy.RecallPlanStatus.rejected)
        #expect(item.status == Pharmacy.RecallPlanStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRecallPlan("code-589", title: "title-364")
        item.status = Pharmacy.RecallPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallPlanStatus.proposed) }
    }
}
