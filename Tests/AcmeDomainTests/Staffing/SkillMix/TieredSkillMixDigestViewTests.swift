@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredSkillMixDigest("code-348", label: "label-141")
        let view = Staffing.toTieredSkillMixDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredSkillMixDigestViews([item, item]).count == 2)
    }
}
