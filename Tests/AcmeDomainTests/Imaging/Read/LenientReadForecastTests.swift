@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadForecastTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newLenientReadForecast("code-582", label: "label-936")
        #expect(item.status == Imaging.LenientReadForecastStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newLenientReadForecast("code-582", label: "label-936")
        try item.moveTo(Imaging.LenientReadForecastStatus.reopened)
        #expect(item.status == Imaging.LenientReadForecastStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newLenientReadForecast("code-582", label: "label-936")
        item.status = Imaging.LenientReadForecastStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientReadForecastStatus.`open`) }
    }
}
