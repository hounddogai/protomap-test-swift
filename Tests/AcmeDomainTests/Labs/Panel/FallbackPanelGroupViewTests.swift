@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackPanelGroup("code-296", name: "name-977")
        let view = Labs.toFallbackPanelGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackPanelGroupViews([item, item]).count == 2)
    }
}
