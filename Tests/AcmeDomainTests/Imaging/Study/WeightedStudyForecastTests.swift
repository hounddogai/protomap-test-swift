@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedStudyForecastTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newWeightedStudyForecast("code-706", name: "name-281")
        #expect(item.status == Imaging.WeightedStudyForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newWeightedStudyForecast("code-706", name: "name-281")
        try item.moveTo(Imaging.WeightedStudyForecastStatus.warming)
        #expect(item.status == Imaging.WeightedStudyForecastStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newWeightedStudyForecast("code-706", name: "name-281")
        item.status = Imaging.WeightedStudyForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedStudyForecastStatus.idle) }
    }
}
