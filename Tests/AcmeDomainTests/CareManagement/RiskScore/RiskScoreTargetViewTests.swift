@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRiskScoreTarget("code-264", label: "label-507")
        let view = CareManagement.toRiskScoreTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRiskScoreTargetViews([item, item]).count == 2)
    }
}
