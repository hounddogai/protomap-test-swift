@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingDischargePlanScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRollingDischargePlanSchedule("code-275", label: "label-597")
        let view = BedManagement.toRollingDischargePlanScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRollingDischargePlanScheduleViews([item, item]).count == 2)
    }
}
