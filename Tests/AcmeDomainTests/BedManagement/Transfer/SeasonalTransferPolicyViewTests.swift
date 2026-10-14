@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalTransferPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newSeasonalTransferPolicy("code-856", name: "name-218")
        let view = BedManagement.toSeasonalTransferPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toSeasonalTransferPolicyViews([item, item]).count == 2)
    }
}
