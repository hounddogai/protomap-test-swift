@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistProfile("code-206", label: "label-894")
        let view = Imaging.toWorklistProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistProfileViews([item, item]).count == 2)
    }
}
