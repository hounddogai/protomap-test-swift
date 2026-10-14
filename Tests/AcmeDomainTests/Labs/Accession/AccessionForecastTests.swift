@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionForecastTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newAccessionForecast("code-663", title: "title-919")
        #expect(item.status == Labs.AccessionForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newAccessionForecast("code-663", title: "title-919")
        try item.moveTo(Labs.AccessionForecastStatus.inProgress)
        #expect(item.status == Labs.AccessionForecastStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newAccessionForecast("code-663", title: "title-919")
        item.status = Labs.AccessionForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionForecastStatus.planned) }
    }
}
