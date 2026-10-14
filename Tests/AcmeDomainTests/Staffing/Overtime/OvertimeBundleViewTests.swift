@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeBundle("code-168", title: "title-603")
        let view = Staffing.toOvertimeBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeBundleViews([item, item]).count == 2)
    }
}
