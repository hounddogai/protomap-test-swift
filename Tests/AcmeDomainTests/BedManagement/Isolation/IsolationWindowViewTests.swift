@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationWindow("code-701", label: "label-685")
        let view = BedManagement.toIsolationWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationWindowViews([item, item]).count == 2)
    }
}
