@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedPriorityProfileTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newBatchedPriorityProfile("code-296", title: "title-995")
        #expect(item.status == Imaging.BatchedPriorityProfileStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newBatchedPriorityProfile("code-296", title: "title-995")
        try item.moveTo(Imaging.BatchedPriorityProfileStatus.inReview)
        #expect(item.status == Imaging.BatchedPriorityProfileStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newBatchedPriorityProfile("code-296", title: "title-995")
        item.status = Imaging.BatchedPriorityProfileStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.BatchedPriorityProfileStatus.`open`) }
    }
}
