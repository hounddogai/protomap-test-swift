@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalCredentialDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalCredentialDraft("code-629", name: "name-684")
        let view = Staffing.toRegionalCredentialDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalCredentialDraftViews([item, item]).count == 2)
    }
}
