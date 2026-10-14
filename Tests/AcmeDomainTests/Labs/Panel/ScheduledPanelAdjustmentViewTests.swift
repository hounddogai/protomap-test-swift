@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledPanelAdjustment("code-826", label: "label-526")
        let view = Labs.toScheduledPanelAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledPanelAdjustmentViews([item, item]).count == 2)
    }
}
