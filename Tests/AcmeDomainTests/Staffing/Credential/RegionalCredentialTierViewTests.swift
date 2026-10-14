@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalCredentialTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalCredentialTier("code-71", name: "name-894")
        let view = Staffing.toRegionalCredentialTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalCredentialTierViews([item, item]).count == 2)
    }
}
