@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelBaseline("code-335", title: "title-574")
        let view = Labs.toPanelBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelBaselineViews([item, item]).count == 2)
    }
}
