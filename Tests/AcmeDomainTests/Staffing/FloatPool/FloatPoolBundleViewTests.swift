@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolBundle("code-151", label: "label-790")
        let view = Staffing.toFloatPoolBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolBundleViews([item, item]).count == 2)
    }
}
