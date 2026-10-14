@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRollingCareGapSchedule("code-810", title: "title-634")
        let view = CareManagement.toRollingCareGapScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRollingCareGapScheduleViews([item, item]).count == 2)
    }
}
