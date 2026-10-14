@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolForecastTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newScheduledCareProtocolForecast("code-160", name: "name-140")
        #expect(item.status == Imaging.ScheduledCareProtocolForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newScheduledCareProtocolForecast("code-160", name: "name-140")
        try item.moveTo(Imaging.ScheduledCareProtocolForecastStatus.published)
        #expect(item.status == Imaging.ScheduledCareProtocolForecastStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newScheduledCareProtocolForecast("code-160", name: "name-140")
        item.status = Imaging.ScheduledCareProtocolForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledCareProtocolForecastStatus.created) }
    }
}
