@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredCareGapAudit("code-548", title: "title-639")
        let view = CareManagement.toTieredCareGapAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredCareGapAuditViews([item, item]).count == 2)
    }
}
