@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveCareProtocolBudgetTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newAdaptiveCareProtocolBudget("code-804", label: "label-604")
        #expect(item.status == Imaging.AdaptiveCareProtocolBudgetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newAdaptiveCareProtocolBudget("code-804", label: "label-604")
        try item.moveTo(Imaging.AdaptiveCareProtocolBudgetStatus.withdrawn)
        #expect(item.status == Imaging.AdaptiveCareProtocolBudgetStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newAdaptiveCareProtocolBudget("code-804", label: "label-604")
        item.status = Imaging.AdaptiveCareProtocolBudgetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveCareProtocolBudgetStatus.proposed) }
    }
}
