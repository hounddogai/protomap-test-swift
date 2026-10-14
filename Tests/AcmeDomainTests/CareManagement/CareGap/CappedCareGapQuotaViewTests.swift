@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCappedCareGapQuota("code-760", label: "label-638")
        let view = CareManagement.toCappedCareGapQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCappedCareGapQuotaViews([item, item]).count == 2)
    }
}
