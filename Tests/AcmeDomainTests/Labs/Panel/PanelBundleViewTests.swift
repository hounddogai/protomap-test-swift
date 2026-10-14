@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelBundle("code-837", name: "name-18")
        let view = Labs.toPanelBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelBundleViews([item, item]).count == 2)
    }
}
