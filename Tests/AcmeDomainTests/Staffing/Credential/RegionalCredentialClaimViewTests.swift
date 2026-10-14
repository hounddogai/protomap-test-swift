@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalCredentialClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalCredentialClaim("code-158", label: "label-566")
        let view = Staffing.toRegionalCredentialClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalCredentialClaimViews([item, item]).count == 2)
    }
}
