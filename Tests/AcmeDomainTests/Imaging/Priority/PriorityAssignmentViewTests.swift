@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityAssignment("code-894", label: "label-663")
        let view = Imaging.toPriorityAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityAssignmentViews([item, item]).count == 2)
    }
}
