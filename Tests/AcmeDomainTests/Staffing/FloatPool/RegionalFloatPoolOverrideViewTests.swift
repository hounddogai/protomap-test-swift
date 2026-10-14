@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalFloatPoolOverride("code-321", title: "title-775")
        let view = Staffing.toRegionalFloatPoolOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalFloatPoolOverrideViews([item, item]).count == 2)
    }
}
