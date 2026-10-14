@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialRequest("code-389", title: "title-654")
        let view = Staffing.toCredentialRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialRequestViews([item, item]).count == 2)
    }
}
