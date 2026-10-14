@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialGroup("code-288", name: "name-620")
        let view = Staffing.toCredentialGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialGroupViews([item, item]).count == 2)
    }
}
