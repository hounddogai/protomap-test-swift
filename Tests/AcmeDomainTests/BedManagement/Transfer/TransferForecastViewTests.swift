@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferForecast("code-955", name: "name-384")
        let view = BedManagement.toTransferForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferForecastViews([item, item]).count == 2)
    }
}
