@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimePlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newBatchedOvertimePlan("code-998", name: "name-320")
        let view = Staffing.toBatchedOvertimePlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toBatchedOvertimePlanViews([item, item]).count == 2)
    }
}
