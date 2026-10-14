@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskReservationTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newTaskReservation("code-229", title: "title-880")
        #expect(item.status == ClinicalOps.TaskReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newTaskReservation("code-229", title: "title-880")
        try item.moveTo(ClinicalOps.TaskReservationStatus.completed)
        #expect(item.status == ClinicalOps.TaskReservationStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newTaskReservation("code-229", title: "title-880")
        item.status = ClinicalOps.TaskReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskReservationStatus.planned) }
    }
}
