@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixMetric("code-4", title: "title-999")
        let view = Staffing.toSkillMixMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixMetricViews([item, item]).count == 2)
    }
}
