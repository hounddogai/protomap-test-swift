@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardPreferenceTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newBedBoardPreference("code-328", title: "title-588")
        #expect(item.status == BedManagement.BedBoardPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newBedBoardPreference("code-328", title: "title-588")
        try item.moveTo(BedManagement.BedBoardPreferenceStatus.pending)
        #expect(item.status == BedManagement.BedBoardPreferenceStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newBedBoardPreference("code-328", title: "title-588")
        item.status = BedManagement.BedBoardPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardPreferenceStatus.draft) }
    }
}
