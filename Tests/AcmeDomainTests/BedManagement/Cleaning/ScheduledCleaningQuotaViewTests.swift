@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledCleaningQuota("code-751", name: "name-72")
        let view = BedManagement.toScheduledCleaningQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledCleaningQuotaViews([item, item]).count == 2)
    }
}
