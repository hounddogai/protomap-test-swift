@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityForecastTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newPriorityForecast("code-524", title: "title-882")
        #expect(item.status == Imaging.PriorityForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newPriorityForecast("code-524", title: "title-882")
        try item.moveTo(Imaging.PriorityForecastStatus.validated)
        #expect(item.status == Imaging.PriorityForecastStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newPriorityForecast("code-524", title: "title-882")
        item.status = Imaging.PriorityForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityForecastStatus.created) }
    }
}
