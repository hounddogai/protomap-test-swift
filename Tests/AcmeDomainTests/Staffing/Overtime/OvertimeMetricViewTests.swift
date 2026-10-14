@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeMetric("code-574", title: "title-663")
        let view = Staffing.toOvertimeMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeMetricViews([item, item]).count == 2)
    }
}
