@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusQuota("code-968", title: "title-901")
        let view = BedManagement.toCensusQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusQuotaViews([item, item]).count == 2)
    }
}
