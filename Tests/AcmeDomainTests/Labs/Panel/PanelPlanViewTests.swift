@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelPlan("code-923", title: "title-507")
        let view = Labs.toPanelPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelPlanViews([item, item]).count == 2)
    }
}
