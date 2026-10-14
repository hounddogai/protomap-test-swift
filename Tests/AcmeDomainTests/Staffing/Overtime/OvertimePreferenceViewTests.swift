@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimePreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimePreference("code-719", title: "title-69")
        let view = Staffing.toOvertimePreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimePreferenceViews([item, item]).count == 2)
    }
}
