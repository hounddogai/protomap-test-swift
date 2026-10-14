@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualSkillMixScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newManualSkillMixSchedule("code-898", label: "label-643")
        let view = Staffing.toManualSkillMixScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toManualSkillMixScheduleViews([item, item]).count == 2)
    }
}
