@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialClaim("code-593", title: "title-701")
        let view = Staffing.toCredentialClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialClaimViews([item, item]).count == 2)
    }
}
