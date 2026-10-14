@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredModalityForecastTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newTieredModalityForecast("code-31", title: "title-452")
        #expect(item.status == Imaging.TieredModalityForecastStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newTieredModalityForecast("code-31", title: "title-452")
        try item.moveTo(Imaging.TieredModalityForecastStatus.revoked)
        #expect(item.status == Imaging.TieredModalityForecastStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newTieredModalityForecast("code-31", title: "title-452")
        item.status = Imaging.TieredModalityForecastStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredModalityForecastStatus.requested) }
    }
}
