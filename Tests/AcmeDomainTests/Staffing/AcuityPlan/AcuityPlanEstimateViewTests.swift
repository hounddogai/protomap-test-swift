@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAcuityPlanEstimate("code-423", label: "label-49")
        let view = Staffing.toAcuityPlanEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAcuityPlanEstimateViews([item, item]).count == 2)
    }
}
