@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedIsolationScheduleTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCappedIsolationSchedule("code-457", name: "name-113")
        #expect(item.status == BedManagement.CappedIsolationScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newCappedIsolationSchedule("code-457", name: "name-113")
        try item.moveTo(BedManagement.CappedIsolationScheduleStatus.done)
        #expect(item.status == BedManagement.CappedIsolationScheduleStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCappedIsolationSchedule("code-457", name: "name-113")
        item.status = BedManagement.CappedIsolationScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedIsolationScheduleStatus.new) }
    }
}
