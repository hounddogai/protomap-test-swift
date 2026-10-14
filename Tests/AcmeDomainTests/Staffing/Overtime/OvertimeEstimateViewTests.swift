@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeEstimate("code-387", label: "label-39")
        let view = Staffing.toOvertimeEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeEstimateViews([item, item]).count == 2)
    }
}
