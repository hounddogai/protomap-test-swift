@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningPreferenceTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newDefaultCleaningPreference("code-198", title: "title-593")
        #expect(item.status == BedManagement.DefaultCleaningPreferenceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newDefaultCleaningPreference("code-198", title: "title-593")
        try item.moveTo(BedManagement.DefaultCleaningPreferenceStatus.granted)
        #expect(item.status == BedManagement.DefaultCleaningPreferenceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newDefaultCleaningPreference("code-198", title: "title-593")
        item.status = BedManagement.DefaultCleaningPreferenceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultCleaningPreferenceStatus.requested) }
    }
}
