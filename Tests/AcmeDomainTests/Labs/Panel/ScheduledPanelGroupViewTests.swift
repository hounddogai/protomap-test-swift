@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledPanelGroup("code-533", title: "title-759")
        let view = Labs.toScheduledPanelGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledPanelGroupViews([item, item]).count == 2)
    }
}
