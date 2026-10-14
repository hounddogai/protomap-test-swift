@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveStudyManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptiveStudyManifest("code-558", label: "label-867")
        let view = Imaging.toAdaptiveStudyManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptiveStudyManifestViews([item, item]).count == 2)
    }
}
