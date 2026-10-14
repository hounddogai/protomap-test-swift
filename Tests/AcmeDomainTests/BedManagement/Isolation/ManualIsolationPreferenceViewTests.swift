@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualIsolationPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualIsolationPreference("code-511", name: "name-949")
        let view = BedManagement.toManualIsolationPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualIsolationPreferenceViews([item, item]).count == 2)
    }
}
