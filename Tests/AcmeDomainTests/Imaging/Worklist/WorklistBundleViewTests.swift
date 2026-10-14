@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistBundle("code-259", label: "label-566")
        let view = Imaging.toWorklistBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistBundleViews([item, item]).count == 2)
    }
}
