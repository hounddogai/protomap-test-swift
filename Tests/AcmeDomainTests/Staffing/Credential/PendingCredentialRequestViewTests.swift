@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPendingCredentialRequest("code-789", title: "title-547")
        let view = Staffing.toPendingCredentialRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPendingCredentialRequestViews([item, item]).count == 2)
    }
}
