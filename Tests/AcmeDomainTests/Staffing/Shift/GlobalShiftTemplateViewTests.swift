@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newGlobalShiftTemplate("code-606", label: "label-987")
        let view = Staffing.toGlobalShiftTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toGlobalShiftTemplateViews([item, item]).count == 2)
    }
}
