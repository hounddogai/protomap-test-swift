@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalFloatPoolAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newGlobalFloatPoolAdjustment("code-289", label: "label-63")
        let view = Staffing.toGlobalFloatPoolAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toGlobalFloatPoolAdjustmentViews([item, item]).count == 2)
    }
}
