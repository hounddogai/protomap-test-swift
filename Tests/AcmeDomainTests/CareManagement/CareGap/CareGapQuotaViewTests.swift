@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapQuota("code-519", title: "title-10")
        let view = CareManagement.toCareGapQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapQuotaViews([item, item]).count == 2)
    }
}
