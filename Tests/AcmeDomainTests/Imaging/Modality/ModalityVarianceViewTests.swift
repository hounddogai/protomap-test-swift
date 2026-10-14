@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityVariance("code-987", label: "label-414")
        let view = Imaging.toModalityVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityVarianceViews([item, item]).count == 2)
    }
}
