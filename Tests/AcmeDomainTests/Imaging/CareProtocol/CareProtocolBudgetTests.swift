@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBudgetTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newCareProtocolBudget("code-988", name: "name-783")
        #expect(item.status == Imaging.CareProtocolBudgetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newCareProtocolBudget("code-988", name: "name-783")
        try item.moveTo(Imaging.CareProtocolBudgetStatus.granted)
        #expect(item.status == Imaging.CareProtocolBudgetStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newCareProtocolBudget("code-988", name: "name-783")
        item.status = Imaging.CareProtocolBudgetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolBudgetStatus.requested) }
    }
}
