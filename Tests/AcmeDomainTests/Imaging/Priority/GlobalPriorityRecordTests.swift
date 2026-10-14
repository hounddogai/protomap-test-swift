@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPriorityRecordTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newGlobalPriorityRecord("code-722", label: "label-831")
        #expect(item.status == Imaging.GlobalPriorityRecordStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newGlobalPriorityRecord("code-722", label: "label-831")
        try item.moveTo(Imaging.GlobalPriorityRecordStatus.inReview)
        #expect(item.status == Imaging.GlobalPriorityRecordStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newGlobalPriorityRecord("code-722", label: "label-831")
        item.status = Imaging.GlobalPriorityRecordStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalPriorityRecordStatus.`open`) }
    }
}
