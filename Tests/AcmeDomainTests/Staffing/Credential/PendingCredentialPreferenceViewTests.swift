@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPendingCredentialPreference("code-664", name: "name-304")
        let view = Staffing.toPendingCredentialPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPendingCredentialPreferenceViews([item, item]).count == 2)
    }
}
