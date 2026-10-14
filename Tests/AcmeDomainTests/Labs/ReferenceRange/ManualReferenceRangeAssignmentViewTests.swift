@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualReferenceRangeAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newManualReferenceRangeAssignment("code-646", name: "name-779")
        let view = Labs.toManualReferenceRangeAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toManualReferenceRangeAssignmentViews([item, item]).count == 2)
    }
}
