@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftForecast("code-12", title: "title-948")
        let view = Staffing.toShiftForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftForecastViews([item, item]).count == 2)
    }
}
