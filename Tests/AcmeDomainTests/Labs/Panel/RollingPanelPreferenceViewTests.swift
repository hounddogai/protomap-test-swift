@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingPanelPreference("code-842", label: "label-603")
        let view = Labs.toRollingPanelPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingPanelPreferenceViews([item, item]).count == 2)
    }
}
