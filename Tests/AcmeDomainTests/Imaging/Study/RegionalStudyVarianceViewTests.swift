@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRegionalStudyVariance("code-54", title: "title-65")
        let view = Imaging.toRegionalStudyVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRegionalStudyVarianceViews([item, item]).count == 2)
    }
}
