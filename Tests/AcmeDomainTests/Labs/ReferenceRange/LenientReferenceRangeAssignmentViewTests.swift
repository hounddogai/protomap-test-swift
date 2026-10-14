@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLenientReferenceRangeAssignment("code-341", label: "label-48")
        let view = Labs.toLenientReferenceRangeAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLenientReferenceRangeAssignmentViews([item, item]).count == 2)
    }
}
