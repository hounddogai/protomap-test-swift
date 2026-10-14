@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSeasonalSkillMixSegment("code-158", name: "name-20")
        let view = Staffing.toSeasonalSkillMixSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSeasonalSkillMixSegmentViews([item, item]).count == 2)
    }
}
