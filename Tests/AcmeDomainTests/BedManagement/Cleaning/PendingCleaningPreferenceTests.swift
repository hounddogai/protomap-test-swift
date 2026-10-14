@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCleaningPreferenceTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newPendingCleaningPreference("code-285", label: "label-373")
        #expect(item.status == BedManagement.PendingCleaningPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newPendingCleaningPreference("code-285", label: "label-373")
        try item.moveTo(BedManagement.PendingCleaningPreferenceStatus.active)
        #expect(item.status == BedManagement.PendingCleaningPreferenceStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newPendingCleaningPreference("code-285", label: "label-373")
        item.status = BedManagement.PendingCleaningPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingCleaningPreferenceStatus.draft) }
    }
}
