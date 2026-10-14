@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixForecast("code-186", title: "title-686")
        let view = Staffing.toSkillMixForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixForecastViews([item, item]).count == 2)
    }
}
