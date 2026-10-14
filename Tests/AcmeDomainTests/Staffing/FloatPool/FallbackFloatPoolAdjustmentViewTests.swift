@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackFloatPoolAdjustment("code-786", label: "label-187")
        let view = Staffing.toFallbackFloatPoolAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackFloatPoolAdjustmentViews([item, item]).count == 2)
    }
}
