@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationForecast("code-165", name: "name-394")
        let view = BedManagement.toIsolationForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationForecastViews([item, item]).count == 2)
    }
}
