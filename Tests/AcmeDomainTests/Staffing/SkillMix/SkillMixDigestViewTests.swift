@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixDigest("code-488", label: "label-317")
        let view = Staffing.toSkillMixDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixDigestViews([item, item]).count == 2)
    }
}
