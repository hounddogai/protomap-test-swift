@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierAssignment("code-773", name: "name-322")
        let view = Labs.toCourierAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierAssignmentViews([item, item]).count == 2)
    }
}
