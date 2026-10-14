@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictTaskMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newStrictTaskMilestone("code-424", title: "title-628")
        let view = ClinicalOps.toStrictTaskMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toStrictTaskMilestoneViews([item, item]).count == 2)
    }
}
