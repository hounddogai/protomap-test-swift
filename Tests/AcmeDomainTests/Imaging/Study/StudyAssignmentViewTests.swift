@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyAssignment("code-876", name: "name-839")
        let view = Imaging.toStudyAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyAssignmentViews([item, item]).count == 2)
    }
}
