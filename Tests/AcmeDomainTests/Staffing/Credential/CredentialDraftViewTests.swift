@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialDraft("code-135", title: "title-211")
        let view = Staffing.toCredentialDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialDraftViews([item, item]).count == 2)
    }
}
