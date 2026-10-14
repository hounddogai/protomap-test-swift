@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyIsolationForecast("code-867", name: "name-22")
        let view = BedManagement.toLegacyIsolationForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyIsolationForecastViews([item, item]).count == 2)
    }
}
