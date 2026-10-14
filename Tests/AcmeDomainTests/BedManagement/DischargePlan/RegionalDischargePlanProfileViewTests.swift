@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalDischargePlanProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRegionalDischargePlanProfile("code-925", title: "title-428")
        let view = BedManagement.toRegionalDischargePlanProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRegionalDischargePlanProfileViews([item, item]).count == 2)
    }
}
