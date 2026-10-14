@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryShiftPreference("code-104", title: "title-460")
        let view = Staffing.toPrimaryShiftPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryShiftPreferenceViews([item, item]).count == 2)
    }
}
