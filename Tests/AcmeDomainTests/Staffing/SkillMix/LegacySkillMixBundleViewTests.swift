@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacySkillMixBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLegacySkillMixBundle("code-380", label: "label-25")
        let view = Staffing.toLegacySkillMixBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLegacySkillMixBundleViews([item, item]).count == 2)
    }
}
