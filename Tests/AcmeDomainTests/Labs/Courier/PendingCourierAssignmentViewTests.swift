@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingCourierAssignment("code-329", name: "name-263")
        let view = Labs.toPendingCourierAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingCourierAssignmentViews([item, item]).count == 2)
    }
}
