@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveAcuityPlanEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAdaptiveAcuityPlanEstimate("code-865", label: "label-687")
        let view = Staffing.toAdaptiveAcuityPlanEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAdaptiveAcuityPlanEstimateViews([item, item]).count == 2)
    }
}
