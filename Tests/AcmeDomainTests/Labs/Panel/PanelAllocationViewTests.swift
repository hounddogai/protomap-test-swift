@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelAllocation("code-627", title: "title-722")
        let view = Labs.toPanelAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelAllocationViews([item, item]).count == 2)
    }
}
