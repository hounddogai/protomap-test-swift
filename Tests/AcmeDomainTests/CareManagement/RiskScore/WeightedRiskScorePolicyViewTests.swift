@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScorePolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newWeightedRiskScorePolicy("code-910", label: "label-257")
        let view = CareManagement.toWeightedRiskScorePolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toWeightedRiskScorePolicyViews([item, item]).count == 2)
    }
}
