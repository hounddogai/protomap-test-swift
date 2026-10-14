@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultReferenceRangeAssignmentTests {
    @Test func startsInRequested() throws {
        let item = Labs.newDefaultReferenceRangeAssignment("code-691", name: "name-83")
        #expect(item.status == Labs.DefaultReferenceRangeAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newDefaultReferenceRangeAssignment("code-691", name: "name-83")
        try item.moveTo(Labs.DefaultReferenceRangeAssignmentStatus.granted)
        #expect(item.status == Labs.DefaultReferenceRangeAssignmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newDefaultReferenceRangeAssignment("code-691", name: "name-83")
        item.status = Labs.DefaultReferenceRangeAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultReferenceRangeAssignmentStatus.requested) }
    }
}
