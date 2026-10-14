@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallBudgetTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRecallBudget("code-812", label: "label-665")
        #expect(item.status == Pharmacy.RecallBudgetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newRecallBudget("code-812", label: "label-665")
        try item.moveTo(Pharmacy.RecallBudgetStatus.inReview)
        #expect(item.status == Pharmacy.RecallBudgetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRecallBudget("code-812", label: "label-665")
        item.status = Pharmacy.RecallBudgetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallBudgetStatus.`open`) }
    }
}
