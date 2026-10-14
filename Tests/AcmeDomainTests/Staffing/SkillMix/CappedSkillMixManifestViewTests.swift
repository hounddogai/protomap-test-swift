@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCappedSkillMixManifest("code-280", label: "label-704")
        let view = Staffing.toCappedSkillMixManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCappedSkillMixManifestViews([item, item]).count == 2)
    }
}
