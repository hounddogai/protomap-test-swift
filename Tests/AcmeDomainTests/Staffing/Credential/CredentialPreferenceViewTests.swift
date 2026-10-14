@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialPreference("code-374", name: "name-680")
        let view = Staffing.toCredentialPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialPreferenceViews([item, item]).count == 2)
    }
}
