@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveSkillMixManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAdaptiveSkillMixManifest("code-727", title: "title-991")
        let view = Staffing.toAdaptiveSkillMixManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAdaptiveSkillMixManifestViews([item, item]).count == 2)
    }
}
