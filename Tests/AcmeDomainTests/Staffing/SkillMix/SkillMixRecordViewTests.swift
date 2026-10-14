@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixRecord("code-418", title: "title-571")
        let view = Staffing.toSkillMixRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixRecordViews([item, item]).count == 2)
    }
}
