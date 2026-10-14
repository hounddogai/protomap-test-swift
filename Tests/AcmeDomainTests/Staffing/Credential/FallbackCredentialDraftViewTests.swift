@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackCredentialDraft("code-65", name: "name-65")
        let view = Staffing.toFallbackCredentialDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackCredentialDraftViews([item, item]).count == 2)
    }
}
