@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledTransferProfileTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newScheduledTransferProfile("code-974", label: "label-108")
        #expect(item.status == BedManagement.ScheduledTransferProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newScheduledTransferProfile("code-974", label: "label-108")
        try item.moveTo(BedManagement.ScheduledTransferProfileStatus.granted)
        #expect(item.status == BedManagement.ScheduledTransferProfileStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newScheduledTransferProfile("code-974", label: "label-108")
        item.status = BedManagement.ScheduledTransferProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledTransferProfileStatus.requested) }
    }
}
