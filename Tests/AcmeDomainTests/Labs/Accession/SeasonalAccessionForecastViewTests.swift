@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSeasonalAccessionForecast("code-12", label: "label-766")
        let view = Labs.toSeasonalAccessionForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSeasonalAccessionForecastViews([item, item]).count == 2)
    }
}
