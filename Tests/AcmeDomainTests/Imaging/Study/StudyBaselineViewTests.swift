@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyBaseline("code-524", label: "label-651")
        let view = Imaging.toStudyBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyBaselineViews([item, item]).count == 2)
    }
}
