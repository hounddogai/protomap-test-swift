@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInteractionForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLenientInteractionForecast("code-680", label: "label-553")
        let view = Pharmacy.toLenientInteractionForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLenientInteractionForecastViews([item, item]).count == 2)
    }
}
