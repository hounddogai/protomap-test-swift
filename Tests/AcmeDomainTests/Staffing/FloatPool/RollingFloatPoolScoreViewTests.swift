@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingFloatPoolScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRollingFloatPoolScore("code-842", label: "label-889")
        let view = Staffing.toRollingFloatPoolScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRollingFloatPoolScoreViews([item, item]).count == 2)
    }
}
