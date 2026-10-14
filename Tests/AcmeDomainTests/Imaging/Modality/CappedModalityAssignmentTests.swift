@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityAssignmentTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newCappedModalityAssignment("code-222", title: "title-990")
        #expect(item.status == Imaging.CappedModalityAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newCappedModalityAssignment("code-222", title: "title-990")
        try item.moveTo(Imaging.CappedModalityAssignmentStatus.inReview)
        #expect(item.status == Imaging.CappedModalityAssignmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newCappedModalityAssignment("code-222", title: "title-990")
        item.status = Imaging.CappedModalityAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedModalityAssignmentStatus.`open`) }
    }
}
