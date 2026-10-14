@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningRecordTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newRollingCleaningRecord("code-694", title: "title-430")
        #expect(item.status == BedManagement.RollingCleaningRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newRollingCleaningRecord("code-694", title: "title-430")
        try item.moveTo(BedManagement.RollingCleaningRecordStatus.scheduled)
        #expect(item.status == BedManagement.RollingCleaningRecordStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newRollingCleaningRecord("code-694", title: "title-430")
        item.status = BedManagement.RollingCleaningRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingCleaningRecordStatus.planned) }
    }
}
