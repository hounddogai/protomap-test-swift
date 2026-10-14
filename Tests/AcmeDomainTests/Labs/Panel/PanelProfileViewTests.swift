@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelProfile("code-739", name: "name-541")
        let view = Labs.toPanelProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelProfileViews([item, item]).count == 2)
    }
}
