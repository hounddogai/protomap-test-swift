@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimePlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimePlan("code-138", title: "title-677")
        let view = Staffing.toOvertimePlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimePlanViews([item, item]).count == 2)
    }
}
