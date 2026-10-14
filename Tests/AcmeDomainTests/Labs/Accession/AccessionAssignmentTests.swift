@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAssignmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newAccessionAssignment("code-286", label: "label-468")
        #expect(item.status == Labs.AccessionAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newAccessionAssignment("code-286", label: "label-468")
        try item.moveTo(Labs.AccessionAssignmentStatus.pending)
        #expect(item.status == Labs.AccessionAssignmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newAccessionAssignment("code-286", label: "label-468")
        item.status = Labs.AccessionAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionAssignmentStatus.draft) }
    }
}
