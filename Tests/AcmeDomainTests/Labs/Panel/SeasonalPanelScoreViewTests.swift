@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalPanelScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSeasonalPanelScore("code-810", name: "name-327")
        let view = Labs.toSeasonalPanelScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSeasonalPanelScoreViews([item, item]).count == 2)
    }
}
