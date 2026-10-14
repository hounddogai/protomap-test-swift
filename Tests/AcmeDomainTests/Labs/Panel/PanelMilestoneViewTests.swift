@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelMilestone("code-508", name: "name-463")
        let view = Labs.toPanelMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelMilestoneViews([item, item]).count == 2)
    }
}
