@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyPanelThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyPanelThreshold("code-758", title: "title-623")
        let view = Labs.toLegacyPanelThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyPanelThresholdViews([item, item]).count == 2)
    }
}
