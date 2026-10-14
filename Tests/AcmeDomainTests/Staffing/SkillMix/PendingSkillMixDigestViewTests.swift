@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingSkillMixDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPendingSkillMixDigest("code-240", title: "title-982")
        let view = Staffing.toPendingSkillMixDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPendingSkillMixDigestViews([item, item]).count == 2)
    }
}
