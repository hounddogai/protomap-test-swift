@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryRiskScoreProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPrimaryRiskScoreProfile("code-50", title: "title-95")
        let view = CareManagement.toPrimaryRiskScoreProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPrimaryRiskScoreProfileViews([item, item]).count == 2)
    }
}
