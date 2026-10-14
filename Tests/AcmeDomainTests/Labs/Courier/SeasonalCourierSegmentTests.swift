@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalCourierSegmentTests {
    @Test func startsInProposed() throws {
        let item = Labs.newSeasonalCourierSegment("code-754", name: "name-578")
        #expect(item.status == Labs.SeasonalCourierSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newSeasonalCourierSegment("code-754", name: "name-578")
        try item.moveTo(Labs.SeasonalCourierSegmentStatus.rejected)
        #expect(item.status == Labs.SeasonalCourierSegmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newSeasonalCourierSegment("code-754", name: "name-578")
        item.status = Labs.SeasonalCourierSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalCourierSegmentStatus.proposed) }
    }
}
