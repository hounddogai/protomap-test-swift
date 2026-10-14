@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionSegmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newSeasonalAccessionSegment("code-52", label: "label-905")
        #expect(item.status == Labs.SeasonalAccessionSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newSeasonalAccessionSegment("code-52", label: "label-905")
        try item.moveTo(Labs.SeasonalAccessionSegmentStatus.active)
        #expect(item.status == Labs.SeasonalAccessionSegmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newSeasonalAccessionSegment("code-52", label: "label-905")
        item.status = Labs.SeasonalAccessionSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalAccessionSegmentStatus.draft) }
    }
}
