@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInventoryForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFallbackInventoryForecast("code-656", name: "name-635")
        let view = Pharmacy.toFallbackInventoryForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFallbackInventoryForecastViews([item, item]).count == 2)
    }
}
