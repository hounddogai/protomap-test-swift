@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertMilestone("code-981", title: "title-672")
        let view = ClinicalOps.toAlertMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertMilestoneViews([item, item]).count == 2)
    }
}
