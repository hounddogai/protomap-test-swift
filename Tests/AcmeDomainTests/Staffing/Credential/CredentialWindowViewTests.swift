@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialWindow("code-33", label: "label-138")
        let view = Staffing.toCredentialWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialWindowViews([item, item]).count == 2)
    }
}
