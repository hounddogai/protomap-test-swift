@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolBaseline("code-74", label: "label-354")
        let view = Staffing.toFloatPoolBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolBaselineViews([item, item]).count == 2)
    }
}
