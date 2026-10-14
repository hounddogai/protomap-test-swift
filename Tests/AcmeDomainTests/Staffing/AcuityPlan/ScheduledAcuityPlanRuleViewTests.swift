@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newScheduledAcuityPlanRule("code-973", label: "label-739")
        let view = Staffing.toScheduledAcuityPlanRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toScheduledAcuityPlanRuleViews([item, item]).count == 2)
    }
}
