@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalIsolationWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalIsolationWindow("code-868", label: "label-458")
        let view = BedManagement.toGlobalIsolationWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalIsolationWindowViews([item, item]).count == 2)
    }
}
