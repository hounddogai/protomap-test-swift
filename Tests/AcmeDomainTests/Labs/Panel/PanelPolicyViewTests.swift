@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelPolicy("code-719", title: "title-559")
        let view = Labs.toPanelPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelPolicyViews([item, item]).count == 2)
    }
}
