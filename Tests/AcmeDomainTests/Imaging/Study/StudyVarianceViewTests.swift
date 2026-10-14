@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyVariance("code-666", title: "title-711")
        let view = Imaging.toStudyVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyVarianceViews([item, item]).count == 2)
    }
}
