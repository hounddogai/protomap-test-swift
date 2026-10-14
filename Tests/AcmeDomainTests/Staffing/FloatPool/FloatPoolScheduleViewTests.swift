@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolSchedule("code-403", name: "name-385")
        let view = Staffing.toFloatPoolScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolScheduleViews([item, item]).count == 2)
    }
}
