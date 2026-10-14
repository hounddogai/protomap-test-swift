@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialAgreement("code-966", title: "title-527")
        let view = Staffing.toCredentialAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialAgreementViews([item, item]).count == 2)
    }
}
