@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityBundle("code-301", title: "title-245")
        let view = Imaging.toPriorityBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityBundleViews([item, item]).count == 2)
    }
}
