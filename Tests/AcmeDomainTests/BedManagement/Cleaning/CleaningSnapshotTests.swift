@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningSnapshotTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newCleaningSnapshot("code-199", name: "name-254")
        #expect(item.status == BedManagement.CleaningSnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newCleaningSnapshot("code-199", name: "name-254")
        try item.moveTo(BedManagement.CleaningSnapshotStatus.granted)
        #expect(item.status == BedManagement.CleaningSnapshotStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newCleaningSnapshot("code-199", name: "name-254")
        item.status = BedManagement.CleaningSnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningSnapshotStatus.requested) }
    }
}
