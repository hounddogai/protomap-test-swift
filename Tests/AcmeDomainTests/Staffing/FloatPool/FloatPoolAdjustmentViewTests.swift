@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolAdjustment("code-582", label: "label-930")
        let view = Staffing.toFloatPoolAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolAdjustmentViews([item, item]).count == 2)
    }
}
