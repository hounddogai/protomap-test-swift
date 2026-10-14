@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveAcuityPlanScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAdaptiveAcuityPlanScore("code-829", label: "label-59")
        let view = Staffing.toAdaptiveAcuityPlanScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAdaptiveAcuityPlanScoreViews([item, item]).count == 2)
    }
}
