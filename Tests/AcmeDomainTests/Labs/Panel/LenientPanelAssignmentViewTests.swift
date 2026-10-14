@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientPanelAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLenientPanelAssignment("code-476", name: "name-816")
        let view = Labs.toLenientPanelAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLenientPanelAssignmentViews([item, item]).count == 2)
    }
}
