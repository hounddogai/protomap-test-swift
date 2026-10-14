@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixBundle("code-688", title: "title-609")
        let view = Staffing.toSkillMixBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixBundleViews([item, item]).count == 2)
    }
}
