@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalReadMilestone("code-966", name: "name-637")
        let view = Imaging.toSeasonalReadMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalReadMilestoneViews([item, item]).count == 2)
    }
}
