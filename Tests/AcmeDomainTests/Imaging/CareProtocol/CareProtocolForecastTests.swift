@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolForecastTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newCareProtocolForecast("code-388", name: "name-487")
        #expect(item.status == Imaging.CareProtocolForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Imaging.newCareProtocolForecast("code-388", name: "name-487")
        try item.moveTo(Imaging.CareProtocolForecastStatus.retired)
        #expect(item.status == Imaging.CareProtocolForecastStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newCareProtocolForecast("code-388", name: "name-487")
        item.status = Imaging.CareProtocolForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolForecastStatus.created) }
    }
}
