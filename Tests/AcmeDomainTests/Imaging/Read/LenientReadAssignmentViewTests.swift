@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLenientReadAssignment("code-135", name: "name-35")
        let view = Imaging.toLenientReadAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLenientReadAssignmentViews([item, item]).count == 2)
    }
}
