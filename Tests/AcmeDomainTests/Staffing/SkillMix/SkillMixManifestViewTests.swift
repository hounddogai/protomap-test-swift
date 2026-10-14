@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixManifest("code-629", name: "name-458")
        let view = Staffing.toSkillMixManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixManifestViews([item, item]).count == 2)
    }
}
