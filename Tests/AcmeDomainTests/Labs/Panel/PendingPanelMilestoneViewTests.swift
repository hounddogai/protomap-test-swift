@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingPanelMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingPanelMilestone("code-879", name: "name-483")
        let view = Labs.toPendingPanelMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingPanelMilestoneViews([item, item]).count == 2)
    }
}
