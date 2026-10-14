@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAssignmentTests {
    @Test func startsInIdle() throws {
        let item = Labs.newReferenceRangeAssignment("code-480", name: "name-78")
        #expect(item.status == Labs.ReferenceRangeAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newReferenceRangeAssignment("code-480", name: "name-78")
        try item.moveTo(Labs.ReferenceRangeAssignmentStatus.ready)
        #expect(item.status == Labs.ReferenceRangeAssignmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newReferenceRangeAssignment("code-480", name: "name-78")
        item.status = Labs.ReferenceRangeAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeAssignmentStatus.idle) }
    }
}
