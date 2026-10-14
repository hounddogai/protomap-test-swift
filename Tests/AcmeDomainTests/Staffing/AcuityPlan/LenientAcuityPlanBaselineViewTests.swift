@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLenientAcuityPlanBaseline("code-328", label: "label-212")
        let view = Staffing.toLenientAcuityPlanBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLenientAcuityPlanBaselineViews([item, item]).count == 2)
    }
}
