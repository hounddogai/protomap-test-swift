@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAdaptiveRiskScoreMilestone("code-361", title: "title-890")
        let view = CareManagement.toAdaptiveRiskScoreMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAdaptiveRiskScoreMilestoneViews([item, item]).count == 2)
    }
}
