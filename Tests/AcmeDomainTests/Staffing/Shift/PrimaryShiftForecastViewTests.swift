@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryShiftForecast("code-469", label: "label-951")
        let view = Staffing.toPrimaryShiftForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryShiftForecastViews([item, item]).count == 2)
    }
}
