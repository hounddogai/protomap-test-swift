@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryForecast("code-925", label: "label-576")
        let view = Pharmacy.toInventoryForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryForecastViews([item, item]).count == 2)
    }
}
