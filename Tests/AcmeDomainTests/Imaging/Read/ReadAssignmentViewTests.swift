@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadAssignment("code-867", name: "name-698")
        let view = Imaging.toReadAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadAssignmentViews([item, item]).count == 2)
    }
}
