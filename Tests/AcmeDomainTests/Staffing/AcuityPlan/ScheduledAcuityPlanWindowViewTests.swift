@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newScheduledAcuityPlanWindow("code-991", title: "title-703")
        let view = Staffing.toScheduledAcuityPlanWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toScheduledAcuityPlanWindowViews([item, item]).count == 2)
    }
}
