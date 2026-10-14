@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationOverride("code-545", title: "title-209")
        let view = BedManagement.toIsolationOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationOverrideViews([item, item]).count == 2)
    }
}
