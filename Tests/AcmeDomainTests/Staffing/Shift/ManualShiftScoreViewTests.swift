@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualShiftScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newManualShiftScore("code-240", name: "name-120")
        let view = Staffing.toManualShiftScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toManualShiftScoreViews([item, item]).count == 2)
    }
}
