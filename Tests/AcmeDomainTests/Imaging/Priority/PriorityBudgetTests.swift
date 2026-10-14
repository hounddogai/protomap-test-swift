@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityBudgetTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newPriorityBudget("code-599", name: "name-371")
        #expect(item.status == Imaging.PriorityBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newPriorityBudget("code-599", name: "name-371")
        try item.moveTo(Imaging.PriorityBudgetStatus.scheduled)
        #expect(item.status == Imaging.PriorityBudgetStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newPriorityBudget("code-599", name: "name-371")
        item.status = Imaging.PriorityBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityBudgetStatus.planned) }
    }
}
