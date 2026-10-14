@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationScheduleTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newIsolationSchedule("code-299", title: "title-420")
        #expect(item.status == BedManagement.IsolationScheduleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = BedManagement.newIsolationSchedule("code-299", title: "title-420")
        try item.moveTo(BedManagement.IsolationScheduleStatus.closed)
        #expect(item.status == BedManagement.IsolationScheduleStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newIsolationSchedule("code-299", title: "title-420")
        item.status = BedManagement.IsolationScheduleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationScheduleStatus.draft) }
    }
}
