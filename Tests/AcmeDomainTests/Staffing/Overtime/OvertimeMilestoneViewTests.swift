@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeMilestone("code-264", name: "name-497")
        let view = Staffing.toOvertimeMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeMilestoneViews([item, item]).count == 2)
    }
}
