@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialProfile("code-589", title: "title-630")
        let view = Staffing.toCredentialProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialProfileViews([item, item]).count == 2)
    }
}
