@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictAccessionAssignmentTests {
    @Test func startsInOpen() throws {
        let item = Labs.newStrictAccessionAssignment("code-822", title: "title-934")
        #expect(item.status == Labs.StrictAccessionAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newStrictAccessionAssignment("code-822", title: "title-934")
        try item.moveTo(Labs.StrictAccessionAssignmentStatus.inReview)
        #expect(item.status == Labs.StrictAccessionAssignmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newStrictAccessionAssignment("code-822", title: "title-934")
        item.status = Labs.StrictAccessionAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictAccessionAssignmentStatus.`open`) }
    }
}
