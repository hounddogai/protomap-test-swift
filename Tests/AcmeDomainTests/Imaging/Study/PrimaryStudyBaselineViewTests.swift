@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrimaryStudyBaseline("code-323", label: "label-84")
        let view = Imaging.toPrimaryStudyBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrimaryStudyBaselineViews([item, item]).count == 2)
    }
}
