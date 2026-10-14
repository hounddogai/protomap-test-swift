@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftBundle("code-583", name: "name-194")
        let view = Staffing.toShiftBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftBundleViews([item, item]).count == 2)
    }
}
