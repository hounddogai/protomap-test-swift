@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalAcuityPlanExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newGlobalAcuityPlanException("code-267", title: "title-829")
        let view = Staffing.toGlobalAcuityPlanExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toGlobalAcuityPlanExceptionViews([item, item]).count == 2)
    }
}
