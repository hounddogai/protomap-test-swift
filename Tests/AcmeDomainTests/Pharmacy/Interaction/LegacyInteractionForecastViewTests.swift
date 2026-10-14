@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyInteractionForecast("code-596", title: "title-988")
        let view = Pharmacy.toLegacyInteractionForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyInteractionForecastViews([item, item]).count == 2)
    }
}
