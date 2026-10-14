@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalHandoffMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newSeasonalHandoffMilestone("code-208", label: "label-666")
        let view = ClinicalOps.toSeasonalHandoffMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toSeasonalHandoffMilestoneViews([item, item]).count == 2)
    }
}
