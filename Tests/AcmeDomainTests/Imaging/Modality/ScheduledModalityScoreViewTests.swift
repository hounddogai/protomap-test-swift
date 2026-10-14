@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledModalityScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledModalityScore("code-441", title: "title-295")
        let view = Imaging.toScheduledModalityScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledModalityScoreViews([item, item]).count == 2)
    }
}
