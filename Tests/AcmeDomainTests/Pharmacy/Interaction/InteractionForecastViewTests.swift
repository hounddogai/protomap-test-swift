@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionForecast("code-659", title: "title-893")
        let view = Pharmacy.toInteractionForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionForecastViews([item, item]).count == 2)
    }
}
