@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedStudyBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedStudyBundle("code-771", label: "label-984")
        let view = Imaging.toWeightedStudyBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedStudyBundleViews([item, item]).count == 2)
    }
}
