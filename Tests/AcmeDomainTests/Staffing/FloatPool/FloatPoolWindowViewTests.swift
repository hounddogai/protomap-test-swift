@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolWindow("code-823", label: "label-929")
        let view = Staffing.toFloatPoolWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolWindowViews([item, item]).count == 2)
    }
}
