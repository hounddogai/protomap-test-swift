@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCensusForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualCensusForecast("code-67", name: "name-533")
        let view = BedManagement.toManualCensusForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualCensusForecastViews([item, item]).count == 2)
    }
}
