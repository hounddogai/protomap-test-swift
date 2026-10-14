@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalWorklistAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalWorklistAssignment("code-414", label: "label-850")
        let view = Imaging.toSeasonalWorklistAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalWorklistAssignmentViews([item, item]).count == 2)
    }
}
