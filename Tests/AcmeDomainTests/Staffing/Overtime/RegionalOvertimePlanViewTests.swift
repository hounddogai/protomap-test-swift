@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimePlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalOvertimePlan("code-893", name: "name-61")
        let view = Staffing.toRegionalOvertimePlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalOvertimePlanViews([item, item]).count == 2)
    }
}
