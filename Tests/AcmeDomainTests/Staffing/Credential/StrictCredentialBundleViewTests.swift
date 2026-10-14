@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictCredentialBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newStrictCredentialBundle("code-304", name: "name-670")
        let view = Staffing.toStrictCredentialBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toStrictCredentialBundleViews([item, item]).count == 2)
    }
}
