@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSeasonalAccessionAdjustment("code-708", name: "name-760")
        let view = Labs.toSeasonalAccessionAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSeasonalAccessionAdjustmentViews([item, item]).count == 2)
    }
}
