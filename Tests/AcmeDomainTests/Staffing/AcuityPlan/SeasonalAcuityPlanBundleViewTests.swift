@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalAcuityPlanBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSeasonalAcuityPlanBundle("code-121", title: "title-473")
        let view = Staffing.toSeasonalAcuityPlanBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSeasonalAcuityPlanBundleViews([item, item]).count == 2)
    }
}
