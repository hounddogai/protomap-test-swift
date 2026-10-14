@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftBaseline("code-281", title: "title-101")
        let view = Staffing.toShiftBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftBaselineViews([item, item]).count == 2)
    }
}
