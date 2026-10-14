@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolRule("code-788", title: "title-620")
        let view = Staffing.toFloatPoolRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolRuleViews([item, item]).count == 2)
    }
}
