@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionAssignment("code-286", label: "label-468")
        let view = Labs.toAccessionAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionAssignmentViews([item, item]).count == 2)
    }
}
