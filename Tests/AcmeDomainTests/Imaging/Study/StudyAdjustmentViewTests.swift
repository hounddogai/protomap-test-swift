@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyAdjustment("code-353", title: "title-402")
        let view = Imaging.toStudyAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyAdjustmentViews([item, item]).count == 2)
    }
}
