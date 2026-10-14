@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityBudgetTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newManualPriorityBudget("code-155", title: "title-14")
        #expect(item.status == Imaging.ManualPriorityBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newManualPriorityBudget("code-155", title: "title-14")
        try item.moveTo(Imaging.ManualPriorityBudgetStatus.inProgress)
        #expect(item.status == Imaging.ManualPriorityBudgetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newManualPriorityBudget("code-155", title: "title-14")
        item.status = Imaging.ManualPriorityBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualPriorityBudgetStatus.planned) }
    }
}
