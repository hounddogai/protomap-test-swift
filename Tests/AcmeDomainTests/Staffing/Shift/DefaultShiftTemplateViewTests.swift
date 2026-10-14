@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newDefaultShiftTemplate("code-523", label: "label-190")
        let view = Staffing.toDefaultShiftTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toDefaultShiftTemplateViews([item, item]).count == 2)
    }
}
