@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledPanelScore("code-812", name: "name-687")
        let view = Labs.toScheduledPanelScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledPanelScoreViews([item, item]).count == 2)
    }
}
