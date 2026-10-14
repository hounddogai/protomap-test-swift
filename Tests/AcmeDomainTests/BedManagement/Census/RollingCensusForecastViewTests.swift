@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCensusForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRollingCensusForecast("code-555", label: "label-986")
        let view = BedManagement.toRollingCensusForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRollingCensusForecastViews([item, item]).count == 2)
    }
}
