@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingStudyBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPendingStudyBaseline("code-661", title: "title-546")
        let view = Imaging.toPendingStudyBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPendingStudyBaselineViews([item, item]).count == 2)
    }
}
