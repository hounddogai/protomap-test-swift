@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingPanelPlan("code-467", label: "label-974")
        let view = Labs.toRollingPanelPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingPanelPlanViews([item, item]).count == 2)
    }
}
