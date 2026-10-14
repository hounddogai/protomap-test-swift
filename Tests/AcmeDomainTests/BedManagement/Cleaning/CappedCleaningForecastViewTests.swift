@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCappedCleaningForecast("code-889", title: "title-477")
        let view = BedManagement.toCappedCleaningForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCappedCleaningForecastViews([item, item]).count == 2)
    }
}
