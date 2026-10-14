@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictShiftThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newStrictShiftThreshold("code-504", label: "label-534")
        let view = Staffing.toStrictShiftThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toStrictShiftThresholdViews([item, item]).count == 2)
    }
}
