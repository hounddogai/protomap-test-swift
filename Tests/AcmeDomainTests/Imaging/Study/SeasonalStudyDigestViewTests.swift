@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalStudyDigest("code-121", label: "label-770")
        let view = Imaging.toSeasonalStudyDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalStudyDigestViews([item, item]).count == 2)
    }
}
