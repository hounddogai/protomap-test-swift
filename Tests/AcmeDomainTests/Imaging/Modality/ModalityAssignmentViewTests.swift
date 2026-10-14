@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityAssignment("code-939", name: "name-102")
        let view = Imaging.toModalityAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityAssignmentViews([item, item]).count == 2)
    }
}
