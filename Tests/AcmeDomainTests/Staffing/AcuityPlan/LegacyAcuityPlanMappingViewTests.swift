@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyAcuityPlanMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLegacyAcuityPlanMapping("code-927", name: "name-51")
        let view = Staffing.toLegacyAcuityPlanMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLegacyAcuityPlanMappingViews([item, item]).count == 2)
    }
}
