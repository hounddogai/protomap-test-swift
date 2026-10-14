@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolTemplate("code-988", name: "name-627")
        let view = Staffing.toFloatPoolTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolTemplateViews([item, item]).count == 2)
    }
}
