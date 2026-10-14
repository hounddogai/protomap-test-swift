@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientResultScheduleTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newLenientResultSchedule("code-112", label: "label-980")
        #expect(item.status == Labs.LenientResultScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newLenientResultSchedule("code-112", label: "label-980")
        try item.moveTo(Labs.LenientResultScheduleStatus.completed)
        #expect(item.status == Labs.LenientResultScheduleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newLenientResultSchedule("code-112", label: "label-980")
        item.status = Labs.LenientResultScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientResultScheduleStatus.planned) }
    }
}
