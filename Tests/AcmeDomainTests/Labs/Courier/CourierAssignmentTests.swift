@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newCourierAssignment("code-773", name: "name-322")
        #expect(item.status == Labs.CourierAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newCourierAssignment("code-773", name: "name-322")
        try item.moveTo(Labs.CourierAssignmentStatus.completed)
        #expect(item.status == Labs.CourierAssignmentStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newCourierAssignment("code-773", name: "name-322")
        item.status = Labs.CourierAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierAssignmentStatus.planned) }
    }
}
