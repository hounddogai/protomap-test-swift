@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenScheduleTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newSpecimenSchedule("code-388", title: "title-320")
        #expect(item.status == Labs.SpecimenScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newSpecimenSchedule("code-388", title: "title-320")
        try item.moveTo(Labs.SpecimenScheduleStatus.completed)
        #expect(item.status == Labs.SpecimenScheduleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newSpecimenSchedule("code-388", title: "title-320")
        item.status = Labs.SpecimenScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenScheduleStatus.planned) }
    }
}
