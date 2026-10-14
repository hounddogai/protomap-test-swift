@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptivePanelMilestone("code-401", name: "name-855")
        let view = Labs.toAdaptivePanelMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptivePanelMilestoneViews([item, item]).count == 2)
    }
}
