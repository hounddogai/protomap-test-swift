@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackAcuityPlanRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackAcuityPlanRequest("code-899", name: "name-709")
        let view = Staffing.toFallbackAcuityPlanRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackAcuityPlanRequestViews([item, item]).count == 2)
    }
}
