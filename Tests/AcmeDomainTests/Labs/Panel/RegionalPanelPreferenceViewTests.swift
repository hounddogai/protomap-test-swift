@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalPanelPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRegionalPanelPreference("code-963", label: "label-386")
        let view = Labs.toRegionalPanelPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRegionalPanelPreferenceViews([item, item]).count == 2)
    }
}
