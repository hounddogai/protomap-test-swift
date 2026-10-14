@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolOverride("code-63", name: "name-265")
        let view = Staffing.toFloatPoolOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolOverrideViews([item, item]).count == 2)
    }
}
