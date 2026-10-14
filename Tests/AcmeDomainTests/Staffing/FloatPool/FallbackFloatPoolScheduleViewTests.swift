@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackFloatPoolSchedule("code-270", title: "title-865")
        let view = Staffing.toFallbackFloatPoolScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackFloatPoolScheduleViews([item, item]).count == 2)
    }
}
