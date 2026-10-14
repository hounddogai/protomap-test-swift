@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixAdjustment("code-271", label: "label-693")
        let view = Staffing.toSkillMixAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixAdjustmentViews([item, item]).count == 2)
    }
}
