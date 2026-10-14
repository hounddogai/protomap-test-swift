@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistBudgetTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newWorklistBudget("code-339", label: "label-603")
        #expect(item.status == Imaging.WorklistBudgetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newWorklistBudget("code-339", label: "label-603")
        try item.moveTo(Imaging.WorklistBudgetStatus.granted)
        #expect(item.status == Imaging.WorklistBudgetStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newWorklistBudget("code-339", label: "label-603")
        item.status = Imaging.WorklistBudgetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistBudgetStatus.requested) }
    }
}
