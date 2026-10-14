@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptivePriorityMilestone("code-169", name: "name-15")
        let view = Imaging.toAdaptivePriorityMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptivePriorityMilestoneViews([item, item]).count == 2)
    }
}
