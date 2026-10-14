@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalCensusQuota("code-269", name: "name-560")
        let view = BedManagement.toGlobalCensusQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalCensusQuotaViews([item, item]).count == 2)
    }
}
