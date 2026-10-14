@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientModalityScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLenientModalityScore("code-900", title: "title-390")
        let view = Imaging.toLenientModalityScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLenientModalityScoreViews([item, item]).count == 2)
    }
}
