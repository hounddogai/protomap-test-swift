@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionScheduleTests {
    @Test func startsInProposed() throws {
        let item = Labs.newAccessionSchedule("code-495", title: "title-883")
        #expect(item.status == Labs.AccessionScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newAccessionSchedule("code-495", title: "title-883")
        try item.moveTo(Labs.AccessionScheduleStatus.rejected)
        #expect(item.status == Labs.AccessionScheduleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newAccessionSchedule("code-495", title: "title-883")
        item.status = Labs.AccessionScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionScheduleStatus.proposed) }
    }
}
