@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelThreshold("code-510", label: "label-496")
        let view = Labs.toPanelThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelThresholdViews([item, item]).count == 2)
    }
}
