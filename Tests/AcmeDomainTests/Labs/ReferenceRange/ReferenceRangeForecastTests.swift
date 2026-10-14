@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeForecastTests {
    @Test func startsInOpen() throws {
        let item = Labs.newReferenceRangeForecast("code-891", title: "title-503")
        #expect(item.status == Labs.ReferenceRangeForecastStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newReferenceRangeForecast("code-891", title: "title-503")
        try item.moveTo(Labs.ReferenceRangeForecastStatus.inReview)
        #expect(item.status == Labs.ReferenceRangeForecastStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newReferenceRangeForecast("code-891", title: "title-503")
        item.status = Labs.ReferenceRangeForecastStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeForecastStatus.`open`) }
    }
}
