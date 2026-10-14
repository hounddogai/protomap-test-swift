@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallForecast("code-715", title: "title-804")
        let view = Pharmacy.toRecallForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallForecastViews([item, item]).count == 2)
    }
}
