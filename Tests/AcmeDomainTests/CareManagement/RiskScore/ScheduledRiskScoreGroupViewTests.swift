@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledRiskScoreGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledRiskScoreGroup("code-86", name: "name-82")
        let view = CareManagement.toScheduledRiskScoreGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledRiskScoreGroupViews([item, item]).count == 2)
    }
}
