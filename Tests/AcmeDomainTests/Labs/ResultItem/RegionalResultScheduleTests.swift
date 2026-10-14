@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalResultScheduleTests {
    @Test func startsInRequested() throws {
        let item = Labs.newRegionalResultSchedule("code-377", name: "name-507")
        #expect(item.status == Labs.RegionalResultScheduleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newRegionalResultSchedule("code-377", name: "name-507")
        try item.moveTo(Labs.RegionalResultScheduleStatus.revoked)
        #expect(item.status == Labs.RegionalResultScheduleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newRegionalResultSchedule("code-377", name: "name-507")
        item.status = Labs.RegionalResultScheduleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RegionalResultScheduleStatus.requested) }
    }
}
