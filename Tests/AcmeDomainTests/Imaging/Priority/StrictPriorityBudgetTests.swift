@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictPriorityBudgetTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newStrictPriorityBudget("code-247", name: "name-487")
        #expect(item.status == Imaging.StrictPriorityBudgetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newStrictPriorityBudget("code-247", name: "name-487")
        try item.moveTo(Imaging.StrictPriorityBudgetStatus.approved)
        #expect(item.status == Imaging.StrictPriorityBudgetStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newStrictPriorityBudget("code-247", name: "name-487")
        item.status = Imaging.StrictPriorityBudgetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictPriorityBudgetStatus.proposed) }
    }
}
