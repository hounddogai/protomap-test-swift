@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledDischargePlanForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledDischargePlanForecast("code-643", label: "label-170")
        let view = BedManagement.toScheduledDischargePlanForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledDischargePlanForecastViews([item, item]).count == 2)
    }
}
