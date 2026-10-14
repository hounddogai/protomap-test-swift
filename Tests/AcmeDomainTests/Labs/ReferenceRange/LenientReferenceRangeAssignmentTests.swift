@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeAssignmentTests {
    @Test func startsInRequested() throws {
        let item = Labs.newLenientReferenceRangeAssignment("code-341", label: "label-48")
        #expect(item.status == Labs.LenientReferenceRangeAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newLenientReferenceRangeAssignment("code-341", label: "label-48")
        try item.moveTo(Labs.LenientReferenceRangeAssignmentStatus.granted)
        #expect(item.status == Labs.LenientReferenceRangeAssignmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newLenientReferenceRangeAssignment("code-341", label: "label-48")
        item.status = Labs.LenientReferenceRangeAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientReferenceRangeAssignmentStatus.requested) }
    }
}
