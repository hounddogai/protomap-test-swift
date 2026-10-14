@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryReadMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPrimaryReadMilestone("code-526", title: "title-648")
        let view = Imaging.toPrimaryReadMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPrimaryReadMilestoneViews([item, item]).count == 2)
    }
}
