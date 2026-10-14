@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredShiftBundle("code-311", title: "title-572")
        let view = Staffing.toTieredShiftBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredShiftBundleViews([item, item]).count == 2)
    }
}
