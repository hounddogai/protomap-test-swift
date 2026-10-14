@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeForecast("code-183", label: "label-447")
        let view = Staffing.toOvertimeForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeForecastViews([item, item]).count == 2)
    }
}
