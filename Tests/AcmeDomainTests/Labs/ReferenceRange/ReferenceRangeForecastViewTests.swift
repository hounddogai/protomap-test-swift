@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeForecast("code-891", title: "title-503")
        let view = Labs.toReferenceRangeForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeForecastViews([item, item]).count == 2)
    }
}
