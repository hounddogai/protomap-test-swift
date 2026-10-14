@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledPriorityScore("code-90", label: "label-405")
        let view = Imaging.toScheduledPriorityScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledPriorityScoreViews([item, item]).count == 2)
    }
}
