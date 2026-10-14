@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationTier("code-842", name: "name-655")
        let view = BedManagement.toIsolationTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationTierViews([item, item]).count == 2)
    }
}
