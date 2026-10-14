@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingIsolationPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRollingIsolationPreference("code-682", name: "name-611")
        let view = BedManagement.toRollingIsolationPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRollingIsolationPreferenceViews([item, item]).count == 2)
    }
}
