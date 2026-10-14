@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalPanelAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newGlobalPanelAdjustment("code-908", title: "title-873")
        let view = Labs.toGlobalPanelAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toGlobalPanelAdjustmentViews([item, item]).count == 2)
    }
}
