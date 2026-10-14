@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientShiftThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLenientShiftThreshold("code-468", name: "name-972")
        let view = Staffing.toLenientShiftThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLenientShiftThresholdViews([item, item]).count == 2)
    }
}
