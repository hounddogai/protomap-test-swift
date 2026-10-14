@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictAcuityPlanBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newStrictAcuityPlanBundle("code-599", title: "title-451")
        let view = Staffing.toStrictAcuityPlanBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toStrictAcuityPlanBundleViews([item, item]).count == 2)
    }
}
