@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalOvertimeBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newGlobalOvertimeBundle("code-674", title: "title-113")
        let view = Staffing.toGlobalOvertimeBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toGlobalOvertimeBundleViews([item, item]).count == 2)
    }
}
