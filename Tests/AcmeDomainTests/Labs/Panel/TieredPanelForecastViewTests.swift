@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newTieredPanelForecast("code-741", title: "title-730")
        let view = Labs.toTieredPanelForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toTieredPanelForecastViews([item, item]).count == 2)
    }
}
