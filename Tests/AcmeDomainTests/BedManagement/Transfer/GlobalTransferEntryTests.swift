@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalTransferEntryTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newGlobalTransferEntry("code-821", title: "title-386")
        #expect(item.status == BedManagement.GlobalTransferEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newGlobalTransferEntry("code-821", title: "title-386")
        try item.moveTo(BedManagement.GlobalTransferEntryStatus.granted)
        #expect(item.status == BedManagement.GlobalTransferEntryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newGlobalTransferEntry("code-821", title: "title-386")
        item.status = BedManagement.GlobalTransferEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalTransferEntryStatus.requested) }
    }
}
