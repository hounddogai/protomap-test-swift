@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialBundle("code-885", name: "name-614")
        let view = Staffing.toCredentialBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialBundleViews([item, item]).count == 2)
    }
}
