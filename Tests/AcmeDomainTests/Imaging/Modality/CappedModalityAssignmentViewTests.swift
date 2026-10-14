@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCappedModalityAssignment("code-222", title: "title-990")
        let view = Imaging.toCappedModalityAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCappedModalityAssignmentViews([item, item]).count == 2)
    }
}
