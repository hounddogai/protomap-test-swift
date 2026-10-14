@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionForecast("code-663", title: "title-919")
        let view = Labs.toAccessionForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionForecastViews([item, item]).count == 2)
    }
}
