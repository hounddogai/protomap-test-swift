@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyResultForecast("code-222", title: "title-245")
        let view = Labs.toLegacyResultForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyResultForecastViews([item, item]).count == 2)
    }
}
