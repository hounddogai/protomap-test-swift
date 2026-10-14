@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultScheduleTests {
    @Test func startsInRequested() throws {
        let item = Labs.newResultSchedule("code-596", title: "title-320")
        #expect(item.status == Labs.ResultScheduleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newResultSchedule("code-596", title: "title-320")
        try item.moveTo(Labs.ResultScheduleStatus.expired)
        #expect(item.status == Labs.ResultScheduleStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newResultSchedule("code-596", title: "title-320")
        item.status = Labs.ResultScheduleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultScheduleStatus.requested) }
    }
}
