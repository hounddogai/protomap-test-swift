@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixThreshold("code-586", title: "title-115")
        let view = Staffing.toSkillMixThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixThresholdViews([item, item]).count == 2)
    }
}
