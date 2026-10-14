@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningDraftTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCleaningDraft("code-414", title: "title-802")
        #expect(item.status == BedManagement.CleaningDraftStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newCleaningDraft("code-414", title: "title-802")
        try item.moveTo(BedManagement.CleaningDraftStatus.active)
        #expect(item.status == BedManagement.CleaningDraftStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCleaningDraft("code-414", title: "title-802")
        item.status = BedManagement.CleaningDraftStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningDraftStatus.draft) }
    }
}
