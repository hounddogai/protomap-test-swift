@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferScheduleTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newTransferSchedule("code-679", name: "name-625")
        #expect(item.status == BedManagement.TransferScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newTransferSchedule("code-679", name: "name-625")
        try item.moveTo(BedManagement.TransferScheduleStatus.reopened)
        #expect(item.status == BedManagement.TransferScheduleStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newTransferSchedule("code-679", name: "name-625")
        item.status = BedManagement.TransferScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferScheduleStatus.`open`) }
    }
}
