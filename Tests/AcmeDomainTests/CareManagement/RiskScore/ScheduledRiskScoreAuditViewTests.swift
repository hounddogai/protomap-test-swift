@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledRiskScoreAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledRiskScoreAudit("code-877", title: "title-974")
        let view = CareManagement.toScheduledRiskScoreAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledRiskScoreAuditViews([item, item]).count == 2)
    }
}
