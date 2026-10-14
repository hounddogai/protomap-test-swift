@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelOverride("code-681", title: "title-144")
        let view = Labs.toPanelOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelOverrideViews([item, item]).count == 2)
    }
}
