@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimarySkillMixManifest("code-621", title: "title-276")
        let view = Staffing.toPrimarySkillMixManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimarySkillMixManifestViews([item, item]).count == 2)
    }
}
