@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRollingOvertimeSegment("code-592", name: "name-840")
        let view = Staffing.toRollingOvertimeSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRollingOvertimeSegmentViews([item, item]).count == 2)
    }
}
