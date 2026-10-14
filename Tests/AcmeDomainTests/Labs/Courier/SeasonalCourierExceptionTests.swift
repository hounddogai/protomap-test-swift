@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalCourierExceptionTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newSeasonalCourierException("code-126", title: "title-295")
        #expect(item.status == Labs.SeasonalCourierExceptionStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newSeasonalCourierException("code-126", title: "title-295")
        try item.moveTo(Labs.SeasonalCourierExceptionStatus.scheduled)
        #expect(item.status == Labs.SeasonalCourierExceptionStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newSeasonalCourierException("code-126", title: "title-295")
        item.status = Labs.SeasonalCourierExceptionStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalCourierExceptionStatus.planned) }
    }
}
