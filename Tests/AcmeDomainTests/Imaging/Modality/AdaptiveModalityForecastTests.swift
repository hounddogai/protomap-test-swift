@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveModalityForecastTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newAdaptiveModalityForecast("code-939", label: "label-348")
        #expect(item.status == Imaging.AdaptiveModalityForecastStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newAdaptiveModalityForecast("code-939", label: "label-348")
        try item.moveTo(Imaging.AdaptiveModalityForecastStatus.resolved)
        #expect(item.status == Imaging.AdaptiveModalityForecastStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newAdaptiveModalityForecast("code-939", label: "label-348")
        item.status = Imaging.AdaptiveModalityForecastStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveModalityForecastStatus.`open`) }
    }
}
